import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/game/firebase_game_service.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/services/map/map_providers.dart';

/// El tablero del mapa que se juega.
final boardProvider = Provider<BoardLayout>(
  (ref) => ref.watch(currentMapProvider).buildBoard(),
);

/// Las reglas. El anfitrión las aplica; la pantalla las usa para saber qué
/// ítems se pueden comprar o usar.
final gameEngineProvider = Provider<GameEngine>(
  (ref) => GameEngine(
    board: ref.watch(boardProvider),
    random: DartRandomSource(),
    minigames: MinigameType.values,
  ),
);

final gameServiceProvider = Provider<GameService>(
  (ref) => FirebaseGameService(
    FirebaseDatabase.instance,
    ref.watch(gameEngineProvider),
  ),
);

/// La partida en vivo, por id de sala.
final gameProvider = StreamProvider.family<GameState?, String>(
  (ref, roomId) => ref.watch(gameServiceProvider).watchGame(roomId),
);
