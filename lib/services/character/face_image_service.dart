import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// Prepara y recorta la foto de la cara. Son funciones puras: no dependen del
/// celular y se pueden correr en otro hilo.
abstract final class FaceImageProcessor {
  /// Lado de la foto final, en píxeles.
  static const int side = 256;

  /// Lado mayor de la foto mientras se edita.
  static const int _editSide = 1280;

  /// Color de lo que queda sin foto al mover o girar: un gris claro.
  static final img.Color _empty = img.ColorRgb8(226, 230, 234);

  /// Endereza la foto y la reduce para editarla. Devuelve null si no es una
  /// imagen válida.
  static FaceSourceImage? prepare(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    // Respeta cómo se sostenía el celular al tomar la foto.
    var image = img.bakeOrientation(decoded);
    final longest = math.max(image.width, image.height);
    if (longest > _editSide) {
      final factor = _editSide / longest;
      image = img.copyResize(
        image,
        width: (image.width * factor).round(),
        height: (image.height * factor).round(),
        interpolation: img.Interpolation.average,
      );
    }
    return FaceSourceImage(
      bytes: Uint8List.fromList(img.encodeJpg(image, quality: 90)),
      width: image.width,
      height: image.height,
    );
  }

  /// Recorta [source] como dice [crop] y la guarda como un JPEG lo bastante
  /// liviano para entrar en [FacePhoto.maxLength]. Es la misma cuenta que usa
  /// el editor para dibujarla: lo que se ve es lo que se guarda.
  static FacePhoto? render(FaceSourceImage source, FaceCrop crop) {
    var image = img.decodeImage(source.bytes);
    if (image == null) return null;

    // Píxeles de la foto por cada píxel del resultado. Si se va a reducir
    // mucho, se baja antes para que no se vea con dientes de sierra.
    final short = math.min(image.width, image.height);
    final reduction = short / (side * crop.scale);
    if (reduction > 2) {
      image = img.copyResize(
        image,
        width: (image.width * 2 / reduction).round(),
        height: (image.height * 2 / reduction).round(),
        interpolation: img.Interpolation.average,
      );
    }

    // Píxeles de la foto por cada lado de la zona.
    final pixels = math.min(image.width, image.height) / crop.scale;
    final cosine = math.cos(-crop.rotation);
    final sine = math.sin(-crop.rotation);
    final output = img.Image(width: side, height: side);

    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        // De la zona a la foto: se deshace mover, girar, zoom y espejo.
        final viewX = (x + 0.5) / side - 0.5 - crop.dx;
        final viewY = (y + 0.5) / side - 0.5 - crop.dy;
        var photoX = (viewX * cosine - viewY * sine) * pixels;
        final photoY = (viewX * sine + viewY * cosine) * pixels;
        if (crop.mirrored) photoX = -photoX;

        final sourceX = photoX + image.width / 2;
        final sourceY = photoY + image.height / 2;
        final inside =
            sourceX >= 0 &&
            sourceY >= 0 &&
            sourceX < image.width &&
            sourceY < image.height;
        output.setPixel(
          x,
          y,
          inside
              ? image.getPixelInterpolate(
                  sourceX,
                  sourceY,
                  interpolation: img.Interpolation.linear,
                )
              : _empty,
        );
      }
    }

    for (final quality in const [80, 70, 60, 50, 40]) {
      final photo = FacePhoto.fromBytes(
        Uint8List.fromList(img.encodeJpg(output, quality: quality)),
      );
      if (photo != null) return photo;
    }
    return null;
  }
}

/// Elige y procesa la foto de la cara. La versión real usa la galería del
/// celular; en las pruebas se puede cambiar por una falsa.
abstract class FaceImageService {
  /// Pide una foto de la galería, lista para editar. Devuelve null si el
  /// jugador cancela. Lanza [CharacterException] con el mensaje a mostrar.
  Future<FaceSourceImage?> pickFromGallery();

  /// Deja una foto (la de la cámara o la guardada) lista para editar. Lanza
  /// [CharacterException] con el mensaje a mostrar.
  Future<FaceSourceImage> prepare(Uint8List bytes);

  /// Hace el recorte final. Lanza [CharacterException] con el mensaje a
  /// mostrar.
  Future<FacePhoto> render(FaceSourceImage source, FaceCrop crop);
}

class ImagePickerFaceImageService implements FaceImageService {
  ImagePickerFaceImageService([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<FaceSourceImage?> pickFromGallery() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return null;
      return await prepare(await file.readAsBytes());
    } on CharacterException {
      rethrow;
    } catch (_) {
      throw const CharacterException(
        'No se pudo abrir la galería. Revisa los permisos.',
      );
    }
  }

  // Decodificar y recortar puede tardar: va en otro hilo.
  @override
  Future<FaceSourceImage> prepare(Uint8List bytes) async {
    final source = await Isolate.run(() => FaceImageProcessor.prepare(bytes));
    if (source == null) {
      throw const CharacterException(
        'No se pudo usar esa imagen. Prueba con otra foto.',
      );
    }
    return source;
  }

  @override
  Future<FacePhoto> render(FaceSourceImage source, FaceCrop crop) async {
    final photo = await Isolate.run(
      () => FaceImageProcessor.render(source, crop),
    );
    if (photo == null) {
      throw const CharacterException(
        'No se pudo preparar la foto. Prueba con otra.',
      );
    }
    return photo;
  }
}
