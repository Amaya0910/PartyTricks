import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/models/map/map_id.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/board_summary.dart';
import 'package:party_tricks/services/map/map_theme.dart';

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
