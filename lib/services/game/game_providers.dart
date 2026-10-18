import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/game/firebase_game_service.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';

final boardProvider = Provider<BoardLayout>((ref) => buildDefaultBoard());

final gameServiceProvider = Provider<GameService>(
  (ref) => FirebaseGameService(
    FirebaseDatabase.instance,
    GameEngine(board: ref.watch(boardProvider), random: DartRandomSource()),
  ),
);

/// La partida en vivo, por id de sala.
final gameProvider = StreamProvider.family<GameState?, String>(
  (ref, roomId) => ref.watch(gameServiceProvider).watchGame(roomId),
);
