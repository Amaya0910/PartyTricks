import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/screens/board_screen.dart';
import 'package:party_tricks/screens/results_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/results/results_providers.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

import '../services/results/fake_results_service.dart';
import '../services/stats/fake_stats_service.dart';

/// La partida en vivo, controlada por la prueba.
class _FakeGameService implements GameService {
  final controller = StreamController<GameState?>.broadcast();
  GameState? last;

  void emit(GameState state) {
    last = state;
    controller.add(state);
  }

  @override
  Stream<GameState?> watchGame(String roomId) async* {
    if (last != null) yield last;
    yield* controller.stream;
  }

  @override
  void Function() runHost(String roomId) => () {};

  @override
  Future<void> sendAction(String roomId, GameAction action) async {}

  @override
  Future<void> startGame(Room room) async {}
}

GameState _game(GamePhase phase) {
  return GameState(
    players: const {
      'u1': PlayerState(id: 'u1', username: 'Tay', diamonds: 4, coins: 18),
      'u2': PlayerState(id: 'u2', username: 'Beto', diamonds: 1, coins: 3),
    },
    turnOrder: const ['u1', 'u2'],
    totalRounds: 5,
    round: 5,
    diamondTileId: 1,
    phase: phase,
  );
}

void main() {
  testWidgets(
    'al terminar muestra los resultados y guarda estadísticas y registro',
    (tester) async {
      tester.view
        ..physicalSize = const Size(400, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final games = _FakeGameService();
      final stats = FakeStatsService();
      final results = FakeResultsService();
      final start = DateTime(2026, 10, 28);

      final container = ProviderContainer(
        overrides: [
          gameServiceProvider.overrideWithValue(games),
          statsServiceProvider.overrideWithValue(stats),
          resultsServiceProvider.overrideWithValue(results),
          friendUidsProvider.overrideWithValue(const {}),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                uid: 'u1',
                email: 'tay@correo.com',
                username: 'Tay',
                friendCode: 'ABC234',
              ),
            ),
          ),
          roomIdentityProvider.overrideWith(
            (ref) async => const RoomIdentity(uid: 'u1', username: 'Tay'),
          ),
          roomProvider('sala').overrideWith(
            (ref) => Stream.value(
              Room(
                id: 'sala',
                code: 'ABC234',
                isPublic: true,
                hostUid: 'u1',
                maxPlayers: 4,
                rounds: 5,
                status: RoomStatus.playing,
                lobbyEndsAt: start,
                players: {
                  'u1': RoomPlayer(uid: 'u1', username: 'Tay', joinedAt: start),
                  'u2': RoomPlayer(
                    uid: 'u2',
                    username: 'Beto',
                    joinedAt: start,
                  ),
                },
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      // En la app el perfil ya está cargado (lo escucha AppGate).
      container.listen(userProfileProvider, (_, _) {});
      await tester.runAsync(() => container.read(userProfileProvider.future));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BoardScreen(roomId: 'sala', isHost: true),
          ),
        ),
      );
      games.emit(_game(GamePhase.minigame));
      await tester.pump();
      await tester.pump();
      expect(find.byType(ResultsScreen), findsNothing);

      games.emit(_game(GamePhase.finished));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ResultsScreen), findsOneWidget);
      expect(find.text('¡Ganaste!'), findsOneWidget);
      // No queda nada del texto provisional de antes.
      expect(find.textContaining('Partida terminada'), findsNothing);

      // El jugador guardó su partida con la XP, y el anfitrión el registro.
      expect(stats.recordedMatches, hasLength(1));
      final (uid, summary) = stats.recordedMatches.single;
      expect(uid, 'u1');
      expect(summary.matchId, 'sala');
      expect(summary.place, 1);
      expect(summary.experience, greaterThan(0));
      expect(summary.isPublic, isTrue);
      final record = results.saved['sala']!;
      expect(record.hostUid, 'u1');
      expect(record.results.winnerIds, ['u1']);

      // Si la partida vuelve a llegar, no se guarda dos veces.
      games.emit(_game(GamePhase.finished));
      await tester.pump();
      expect(stats.recordedMatches, hasLength(1));
    },
  );
}
