import 'dart:ui' show Rect, Size;

import 'package:party_tricks/models/map/board_map.dart';

/// Error al leer el mapa de Tiled, con un mensaje para quien lo arma.
class TiledMapException implements Exception {
  const TiledMapException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lee el archivo `.tmj` (JSON) que guarda Tiled y lo convierte en un
/// [BoardMap].
///
/// Lo que espera del archivo:
/// - Conjuntos de patrones **incrustados** de tipo "colección de imágenes".
/// - Una capa de objetos llamada [tilesLayer] con una plataforma por casilla,
///   cada una con la propiedad entera [tileProperty] (su id).
/// - Cualquier otra capa de objetos (tiendas, puentes, decoraciones).
///
/// Las rutas de las imágenes se toman relativas a la carpeta del mapa, como
/// las guarda Tiled.
class TiledMapParser {
  const TiledMapParser();

  static const tilesLayer = 'casillas';
  static const tileProperty = 'casilla';

  // Banderas que Tiled guarda en los bits altos del gid.
  static const _flipHorizontal = 0x80000000;
  static const _gidMask = 0x0FFFFFFF;

  BoardMap parse(Map<String, dynamic> json, {required String mapDir}) {
    final size = Size(
      _number(json, 'width') * _number(json, 'tilewidth'),
      _number(json, 'height') * _number(json, 'tileheight'),
    );
    final images = _images(json['tilesets'] as List? ?? const [], mapDir);

    final tiles = <int, MapTile>{};
    final objects = <MapSprite>[];
    for (final layer in _objectLayers(json['layers'] as List? ?? const [])) {
      final isTiles = layer['name'] == tilesLayer;
      for (final raw in layer['objects'] as List? ?? const []) {
        final object = raw as Map<String, dynamic>;
        final gid = (object['gid'] as num?)?.toInt();
        if (gid == null) continue; // Rectángulos o notas sin imagen.
        final image = images[gid & _gidMask];
        if (image == null) {
          throw TiledMapException(
            'El objeto ${object['id']} usa una imagen que no está en los '
            'conjuntos de patrones.',
          );
        }
        final sprite = image.place(
          object,
          flipX: gid & _flipHorizontal != 0,
        );
        if (!isTiles) {
          objects.add(sprite);
          continue;
        }
        final id = _intProperty(object, tileProperty);
        if (id == null) {
          throw TiledMapException(
            'A la plataforma ${object['id']} le falta la propiedad '
            '"$tileProperty".',
          );
        }
        if (tiles.containsKey(id)) {
          throw TiledMapException('La casilla $id está repetida.');
        }
        tiles[id] = MapTile(id: id, sprite: sprite);
      }
    }

    return BoardMap(
      size: size,
      tiles: tiles,
      objects: objects,
      background: '$mapDir/fondo.png',
    );
  }

  double _number(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num) {
      throw TiledMapException('Al mapa le falta "$key".');
    }
    return value.toDouble();
  }

  /// Imágenes por gid, de los conjuntos de tipo "colección de imágenes".
  Map<int, _TiledImage> _images(List tilesets, String mapDir) {
    final images = <int, _TiledImage>{};
    for (final raw in tilesets) {
      final tileset = raw as Map<String, dynamic>;
      final source = tileset['source'];
      if (source != null) {
        throw TiledMapException(
          'El conjunto "$source" no está incrustado. En Tiled: Conjunto de '
          'patrones → Incrustar en el mapa.',
        );
      }
      final firstGid = (tileset['firstgid'] as num).toInt();
      final alignment = _Alignment.from(
        tileset['objectalignment'] as String?,
      );
      for (final rawTile in tileset['tiles'] as List? ?? const []) {
        final tile = rawTile as Map<String, dynamic>;
        final image = tile['image'] as String?;
        if (image == null) continue;
        images[firstGid + (tile['id'] as num).toInt()] = _TiledImage(
          asset: resolvePath(mapDir, image),
          width: (tile['imagewidth'] as num).toDouble(),
          height: (tile['imageheight'] as num).toDouble(),
          alignment: alignment,
        );
      }
    }
    return images;
  }

  /// Capas de objetos, también las que están dentro de grupos.
  Iterable<Map<String, dynamic>> _objectLayers(List layers) sync* {
    for (final raw in layers) {
      final layer = raw as Map<String, dynamic>;
      switch (layer['type']) {
        case 'objectgroup':
          yield layer;
        case 'group':
          yield* _objectLayers(layer['layers'] as List? ?? const []);
      }
    }
  }

  int? _intProperty(Map<String, dynamic> object, String name) {
    for (final raw in object['properties'] as List? ?? const []) {
      final property = raw as Map<String, dynamic>;
      if (property['name'] == name) {
        final value = property['value'];
        return value is num ? value.toInt() : int.tryParse('$value');
      }
    }
    return null;
  }

  /// Une [path] (relativa a [dir]) y quita los `.` y `..`. Lanza
  /// [TiledMapException] si queda fuera de `assets/`.
  static String resolvePath(String dir, String path) {
    final parts = <String>[];
    for (final part in '$dir/$path'.replaceAll(r'\', '/').split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else {
        parts.add(part);
      }
    }
    final resolved = parts.join('/');
    if (!resolved.startsWith('assets/')) {
      throw TiledMapException(
        'La imagen "$path" está fuera de la carpeta assets del proyecto.',
      );
    }
    return resolved;
  }
}

/// Punto de la imagen que Tiled usa como posición del objeto
/// ("Alineación de objetos" del conjunto).
class _Alignment {
  const _Alignment(this.x, this.y);

  /// De 0 (izquierda o arriba) a 1 (derecha o abajo).
  final double x;
  final double y;

  static _Alignment from(String? name) => switch (name) {
    'topleft' => const _Alignment(0, 0),
    'top' => const _Alignment(0.5, 0),
    'topright' => const _Alignment(1, 0),
    'left' => const _Alignment(0, 0.5),
    'center' => const _Alignment(0.5, 0.5),
    'right' => const _Alignment(1, 0.5),
    'bottom' => const _Alignment(0.5, 1),
    'bottomright' => const _Alignment(1, 1),
    // "unspecified" y "bottomleft": en mapas ortogonales es abajo a la
    // izquierda.
    _ => const _Alignment(0, 1),
  };
}

class _TiledImage {
  const _TiledImage({
    required this.asset,
    required this.width,
    required this.height,
    required this.alignment,
  });

  final String asset;
  final double width;
  final double height;
  final _Alignment alignment;

  /// Dónde queda la imagen según la posición y el tamaño del objeto.
  MapSprite place(Map<String, dynamic> object, {required bool flipX}) {
    final w = (object['width'] as num?)?.toDouble() ?? width;
    final h = (object['height'] as num?)?.toDouble() ?? height;
    final x = (object['x'] as num).toDouble();
    final y = (object['y'] as num).toDouble();
    return MapSprite(
      asset: asset,
      rect: Rect.fromLTWH(x - alignment.x * w, y - alignment.y * h, w, h),
      flipX: flipX,
    );
  }
}
