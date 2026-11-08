import 'package:party_tricks/models/map/map_id.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Un mapa que se puede jugar: su tablero (tipos de casilla y conexiones) y
/// la carpeta con su dibujo.
///
/// La carpeta guarda, por convención, el archivo de Tiled [tiledMapFile] y el
/// fondo [backgroundFile]. Las piezas compartidas (plataformas, marcas,
/// textura del camino) están en `MapAssets`.
class MapDefinition {
  const MapDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.assetDirectory,
    required this.buildBoard,
  });

  static const tiledMapFile = 'mapa.tmj';
  static const backgroundFile = 'fondo.png';

  /// Id estable, por ejemplo `mapa_01`. Se guarda en la sala y en la
  /// partida, así que no se debe cambiar.
  final String id;

  final String name;
  final String description;

  /// Carpeta del mapa, por ejemplo `assets/maps/mapa_01`. Tiene que estar
  /// en la lista de assets de `pubspec.yaml`.
  final String assetDirectory;

  /// Arma el tablero lógico. Los ids tienen que coincidir con la propiedad
  /// `casilla` de las plataformas en Tiled.
  final BoardLayout Function() buildBoard;

  String get tiledMap => '$assetDirectory/$tiledMapFile';
  String get background => '$assetDirectory/$backgroundFile';
}

/// Los mapas del juego.
class MapCatalog {
  const MapCatalog._();

  static const mapa01 = MapDefinition(
    id: defaultMapId,
    name: 'Mapa 1',
    description: '42 casillas con dos atajos y dos tiendas.',
    assetDirectory: 'assets/maps/mapa_01',
    buildBoard: buildDefaultBoard,
  );

  static const all = [mapa01];

  /// El mapa que se juega si no se elige otro.
  static const defaultMap = mapa01;

  /// El mapa con [id], o null si no existe.
  static MapDefinition? byId(String id) {
    for (final map in all) {
      if (map.id == id) return map;
    }
    return null;
  }

  /// El mapa con [id]. Lanza [UnknownMapException] si esta versión de la
  /// app no lo tiene (una partida creada con una versión más nueva).
  static MapDefinition require(String id) =>
      byId(id) ?? (throw UnknownMapException(id));
}

class UnknownMapException implements Exception {
  const UnknownMapException(this.mapId);

  final String mapId;

  @override
  String toString() => 'Esta versión de la app no tiene el mapa "$mapId".';
}
