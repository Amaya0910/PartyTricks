import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/models/map/map_id.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/board_summary.dart';
import 'package:party_tricks/services/map/boards/mapa_dulces.dart';
import 'package:party_tricks/services/map/map_theme.dart';

/// Muestra en el selector los mapas ocultos (`selectable: false`). Solo para
/// builds internos, como el del tráiler:
/// `flutter run --dart-define=SHOW_HIDDEN_MAPS=true`. El interruptor de
/// Firebase (`config/maps/{id}/enabled`) sigue haciendo falta.
const showHiddenMaps = bool.fromEnvironment('SHOW_HIDDEN_MAPS');

/// Un mapa que se puede jugar: su tablero (tipos de casilla y conexiones),
/// la carpeta con su dibujo y lo que se muestra al elegirlo.
///
/// La carpeta guarda, por convención, el archivo de Tiled [tiledMapFile], el
/// fondo [backgroundFile] y la vista previa [previewFile]. Las piezas que
/// pone el código (camino, marcas, flechas) salen de su [theme].
///
/// Lo que se puede contar del tablero (casillas, atajos, tiendas, tamaño)
/// no se escribe aquí: sale de [summary].
class MapDefinition implements ProtocolFeature {
  const MapDefinition({
    required this.id,
    required this.name,
    required this.shortDescription,
    this.longDescription,
    required this.assetDirectory,
    required this.buildBoard,
    required this.minProtocol,
    this.theme = MapThemeCatalog.classic,
    this.selectable = true,
    this.secondsPerTurn = defaultSecondsPerTurn,
    this.recommendedPlayers = const (
      min: Room.minPlayers,
      max: Room.maxAllowedPlayers,
    ),
  });

  static const tiledMapFile = 'mapa.tmj';
  static const backgroundFile = 'fondo.png';
  static const previewFile = 'preview.png';

  /// Lo que tarda en promedio un turno en el tablero (tirar, caminar, caer)
  /// y un minijuego. Son estimaciones para mostrar, no reglas.
  static const defaultSecondsPerTurn = 20;
  static const minigameSeconds = 40;

  /// Id estable, por ejemplo `mapa_01`. Se guarda en la sala y en la
  /// partida, así que no se debe cambiar.
  final String id;

  final String name;

  /// Una línea, para la lista de mapas.
  final String shortDescription;

  /// Un párrafo para el detalle. Si no hay, se muestra [shortDescription].
  final String? longDescription;

  /// Carpeta del mapa, por ejemplo `assets/maps/mapa_01`. Tiene que estar
  /// en la lista de assets de `pubspec.yaml`.
  final String assetDirectory;

  /// Arma el tablero lógico. Los ids tienen que coincidir con la propiedad
  /// `casilla` de las plataformas en Tiled.
  final BoardLayout Function() buildBoard;

  /// Desde qué [ProtocolLevel] la app conoce este mapa. Un mapa nuevo usa un
  /// nivel nuevo: así las versiones viejas no pueden entrar a sus salas.
  @override
  final int minProtocol;

  /// Cómo se ven el camino, las marcas y las flechas. Por defecto, el
  /// clásico.
  final MapTheme theme;

  /// Si el mapa está listo para publicarse en esta versión. Un mapa oculto
  /// sigue en el catálogo (las salas y partidas que lo usan cargan bien),
  /// pero no aparece en el selector.
  ///
  /// No basta con esto: además tiene que estar encendido en Firebase
  /// (`config/maps/{id}/enabled`, ver `RemoteMapConfig`). Así se puede
  /// lanzar o apagar sin publicar otra versión. Ver
  /// `docs/activacion_mapas.md`.
  final bool selectable;

  /// Cuánto tarda un turno en este mapa. Un mapa con caminos más largos
  /// entre casillas o más bifurcaciones puede subirlo.
  final int secondsPerTurn;

  /// Para cuántos jugadores está pensado. La sala igual acepta de 2 a 6.
  final ({int min, int max}) recommendedPlayers;

  String get tiledMap => '$assetDirectory/$tiledMapFile';
  String get background => '$assetDirectory/$backgroundFile';
  String get previewImage => '$assetDirectory/$previewFile';

  String get description => longDescription ?? shortDescription;

  BoardSummary get summary => BoardSummary.of(buildBoard());

  /// Si las versiones viejas (las que no conocen el protocolo) lo juegan.
  bool get playableByAllVersions => minProtocol <= AppProtocol.legacy;

  /// Minutos aproximados de una partida de [rounds] rondas con [players].
  int estimatedMinutes({required int rounds, required int players}) {
    final perRound = players * secondsPerTurn + minigameSeconds;
    return (rounds * perRound / 60).ceil();
  }
}

/// Los mapas del juego.
class MapCatalog {
  const MapCatalog._();

  static const mapa01 = MapDefinition(
    id: defaultMapId,
    name: 'Mapa 1',
    shortDescription: 'El clásico: un circuito con dos atajos y dos tiendas.',
    longDescription:
        'Un circuito verde que vuelve a la salida. Dos bifurcaciones te '
        'dejan tomar un atajo arriesgado o seguir por el camino largo, y dos '
        'tiendas te esperan a mitad de la vuelta. Ideal para la primera '
        'partida.',
    assetDirectory: 'assets/maps/mapa_01',
    buildBoard: buildDefaultBoard,
    // La 1.0.0 ya lo juega.
    minProtocol: ProtocolLevel.base,
  );

  static const mapaDulces = MapDefinition(
    id: 'mapa_dulces',
    name: 'Mundo Dulce',
    shortDescription: 'Dos mundos de golosinas con vueltas cortas.',
    longDescription:
        'Desde la Plaza de Caramelo eliges el Reino de Chocolate al norte o '
        'el Río de Caramelo al sur. Cada lado tiene su atajo y su tienda, y '
        'las vueltas son cortas: ideal para tus primeras partidas.',
    assetDirectory: 'assets/maps/mapa_dulces',
    buildBoard: buildCandyBoard,
    // Las versiones anteriores no lo conocen: no pueden entrar a sus salas.
    minProtocol: ProtocolLevel.candyMap,
    theme: MapThemeCatalog.candy,
    // Oculto hasta tener el arte final, el .tmj definitivo, las reglas
    // desplegadas y suficientes jugadores con esta versión.
    selectable: false,
  );

  /// Todos los mapas que esta versión conoce, se puedan elegir o no.
  static const all = [mapa01, mapaDulces];

  /// Los que están listos en esta versión. Para el selector falta además
  /// el interruptor remoto (`RemoteMapConfig.availableOf`).
  static List<MapDefinition> get selectable => onlySelectable(all);

  static List<MapDefinition> onlySelectable(List<MapDefinition> maps) => [
    for (final map in maps)
      if (map.selectable) map,
  ];

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
