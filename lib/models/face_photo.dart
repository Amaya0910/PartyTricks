import 'dart:convert';
import 'dart:typed_data';

/// La foto de la cara del jugador, ya recortada y reducida (un JPEG
/// cuadrado de 256 × 256 px). Se guarda como texto en base64 dentro de
/// `users/{uid}` y de `publicProfiles/{uid}` (campo `facePhoto`), así que
/// no hace falta Firebase Storage.
///
/// El tamaño máximo también está en `firestore.rules` (`facePhotoOk`): si
/// cambia aquí, hay que cambiarlo allá.
class FacePhoto {
  const FacePhoto._(this.base64, this.bytes);

  /// Largo máximo del texto en base64.
  static const int maxLength = 60000;

  /// Cuántas fotos leídas se recuerdan (jugadores vistos hace poco).
  static const int _rememberedLimit = 32;

  /// Las últimas fotos leídas, de la más vieja a la más nueva.
  ///
  /// Firestore vuelve a entregar la foto cada vez que cambia algo del perfil
  /// (por ejemplo, las monedas). Devolver la misma foto evita decodificarla
  /// otra vez y, como la imagen en caché se identifica por sus bytes, evita
  /// que Flutter la cargue de nuevo.
  static final Map<String, FacePhoto> _remembered = {};

  /// La foto como texto, tal como se guarda en Firestore.
  final String base64;

  /// La foto ya decodificada, para dibujarla.
  final Uint8List bytes;

  /// Crea la foto desde los bytes de un JPEG. Devuelve null si pesa más de
  /// [maxLength] al convertirla a texto.
  static FacePhoto? fromBytes(Uint8List bytes) {
    final text = base64Encode(bytes);
    if (text.isEmpty || text.length > maxLength) return null;
    return FacePhoto._(text, bytes);
  }

  /// Lee el valor guardado en Firestore. Devuelve null si falta, es muy
  /// grande o no es base64 válido (para no romper la pantalla).
  static FacePhoto? fromStored(Object? raw) {
    if (raw is! String || raw.isEmpty || raw.length > maxLength) return null;
    final known = _remembered.remove(raw);
    if (known != null) return _remembered[raw] = known;
    try {
      final photo = FacePhoto._(raw, base64Decode(raw));
      _remembered[raw] = photo;
      if (_remembered.length > _rememberedLimit) {
        _remembered.remove(_remembered.keys.first);
      }
      return photo;
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is FacePhoto && other.base64 == base64;

  @override
  int get hashCode => base64.hashCode;
}

/// Una foto lista para editar: derecha (ya sin datos de orientación) y con
/// sus medidas, para que el editor y el recorte final coincidan.
class FaceSourceImage {
  const FaceSourceImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Cómo se acomoda la foto en la zona de la cara.
///
/// Las medidas son relativas al lado de esa zona, así que valen igual en la
/// pantalla que en el recorte final.
class FaceCrop {
  const FaceCrop({
    this.scale = 1,
    this.dx = 0,
    this.dy = 0,
    this.rotation = 0,
    this.mirrored = false,
  });

  /// Zoom máximo y mínimo. Con 1, el lado corto de la foto llena la zona.
  static const double minScale = 1;
  static const double maxScale = 5;

  /// Zoom: 1 = el lado corto de la foto mide lo mismo que la zona.
  final double scale;

  /// Cuánto se movió la foto desde el centro, en lados de la zona.
  final double dx;
  final double dy;

  /// Giro en radianes.
  final double rotation;

  /// Si la foto está volteada como en un espejo.
  final bool mirrored;

  FaceCrop copyWith({
    double? scale,
    double? dx,
    double? dy,
    double? rotation,
    bool? mirrored,
  }) {
    return FaceCrop(
      scale: scale ?? this.scale,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      rotation: rotation ?? this.rotation,
      mirrored: mirrored ?? this.mirrored,
    );
  }

  /// La misma posición, sin que la foto se aleje tanto que deje la zona
  /// vacía: el centro de la zona siempre queda sobre la foto.
  FaceCrop clamped(int width, int height) {
    final short = width < height ? width : height;
    final clampedScale = scale.clamp(minScale, maxScale);
    final halfWidth = clampedScale * width / short / 2;
    final halfHeight = clampedScale * height / short / 2;
    return copyWith(
      scale: clampedScale,
      dx: dx.clamp(-halfWidth, halfWidth),
      dy: dy.clamp(-halfHeight, halfHeight),
    );
  }
}
