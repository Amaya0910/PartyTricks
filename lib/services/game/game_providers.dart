import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/game/firebase_game_service.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_providers.dart';

/// El tablero de un mapa, por `mapId`.
final boardProvider = Provider.family<BoardLayout, String>(
  (ref, mapId) => ref.watch(mapDefinitionProvider(mapId)).buildBoard(),
);

/// Las reglas de un mapa, por `mapId`. El anfitrión las aplica; la pantalla
/// las usa para saber qué ítems se pueden comprar o usar.
final gameEngineProvider = Provider.family<GameEngine, String>(
  (ref, mapId) => GameEngine(
    mapId: mapId,
    board: ref.watch(boardProvider(mapId)),
    random: DartRandomSource(),
    minigames: MinigameType.values,
  ),
);

/// Cada partida se juega con el motor del mapa que tiene guardado.
final gameServiceProvider = Provider<GameService>(
  (ref) => FirebaseGameService(FirebaseDatabase.instance, (mapId) {
    // Se revisa antes: Riverpod envolvería el error en ProviderException.
    MapCatalog.require(mapId);
    return ref.read(gameEngineProvider(mapId));
  }),
);

/// La partida en vivo, por id de sala.
final gameProvider = StreamProvider.family<GameState?, String>(
  (ref, roomId) => ref.watch(gameServiceProvider).watchGame(roomId),
);
