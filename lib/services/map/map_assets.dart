import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Rutas de las piezas del mapa que pone el código (no se colocan en Tiled).
class MapAssets {
  const MapAssets._();

  static const _pieces = 'assets/images/mapa/piezas';

  /// Carpeta del mapa que se juega por ahora.
  static const firstMap = 'assets/maps/mapa_01';

  static const pathTexture = '$_pieces/textura_camino.png';
  static const branchArrow = '$_pieces/flecha_bifurcacion.png';

  /// Marca pintada sobre la casilla, o null si no lleva. Las tiendas llevan
  /// su edificio (colocado en Tiled) y las positivas llevarán la moneda.
  static String? markFor(TileType type) => switch (type) {
    TileType.start => '$_pieces/marca_inicio.png',
    TileType.negative => '$_pieces/marca_negativa.png',
    TileType.special => '$_pieces/marca_especial.png',
    TileType.positive || TileType.shop => null,
  };
}
