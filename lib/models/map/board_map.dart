import 'dart:ui' show Offset, Rect, Size;

/// Una imagen colocada en el mapa: plataforma, tienda, puente o decoración.
class MapSprite {
  const MapSprite({
    required this.asset,
    required this.rect,
    this.flipX = false,
  });

  /// Ruta del asset, por ejemplo `assets/images/mapa/piezas/tienda.png`.
  final String asset;

  /// Dónde se dibuja, en píxeles del mundo.
  final Rect rect;

  /// Si se dibuja volteada de izquierda a derecha.
  final bool flipX;

  /// En la vista ¾ lo de más abajo tapa a lo de arriba.
  double get depth => rect.bottom;
}

/// Una casilla del tablero dibujada en el mapa.
class MapTile {
  const MapTile({required this.id, required this.sprite});

  /// El mismo id de la casilla en `BoardLayout`.
  final int id;

  final MapSprite sprite;

  /// Centro del pasto: donde se paran los pies del personaje.
  Offset get anchor => sprite.rect.center;
}

/// Un mapa dibujado: el tamaño del mundo, las casillas y los objetos.
///
/// Solo dice dónde va cada cosa. Los tipos de casilla y cómo se conectan
/// siguen en `BoardLayout`.
class BoardMap {
  const BoardMap({
    required this.size,
    required this.tiles,
    required this.objects,
    required this.background,
  });

  /// Tamaño del mundo en píxeles (2880 × 4320 en el primer mapa).
  final Size size;

  /// Casillas por id.
  final Map<int, MapTile> tiles;

  /// Tiendas, puentes y decoraciones.
  final List<MapSprite> objects;

  /// Imagen de fondo; se estira a [size].
  final String background;

  /// Ids del tablero que el mapa no tiene dibujados.
  List<int> missingTiles(Iterable<int> boardIds) => [
    for (final id in boardIds)
      if (!tiles.containsKey(id)) id,
  ];
}
