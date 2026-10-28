import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/stats_controller.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/services/stats/match_time_tracker.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

import '../services/stats/fake_stats_service.dart';

const _profile = UserProfile(
  uid: 'uid-1',
  email: 'tay@correo.com',
  username: 'Tay_01',
  friendCode: 'ABC234',
);

GameState _game(GamePhase phase) {
  return GameState(
    players: const {
      'uid-1': PlayerState(id: 'uid-1', username: 'Tay_01', diamonds: 2),
      'uid-2': PlayerState(id: 'uid-2', username: 'Beto'),
    },
    turnOrder: const ['uid-1', 'uid-2'],
    totalRounds: 5,
    round: 5,
    diamondTileId: 1,
    phase: phase,
  );
}

void main() {
  final now = DateTime(2026, 10, 27, 18);
  late FakeStatsService service;

  Future<StatsController> controllerFor(UserProfile? profile) async {
    final container = ProviderContainer(
      overrides: [
        statsServiceProvider.overrideWithValue(service),
        clockProvider.overrideWithValue(() => now),
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        // uid-2 es amigo: la partida cuenta como "con amigos".
        friendUidsProvider.overrideWithValue(const {'uid-2'}),
      ],
    );
    addTearDown(container.dispose);
    // Riverpod 3 pausa los proveedores que nadie escucha: sin este listen el
    // perfil falso nunca llega y la prueba se queda esperando.
    container.listen(userProfileProvider, (_, _) {});
    await container.read(userProfileProvider.future);
    return container.read(statsControllerProvider);
  }

  setUp(() => service = FakeStatsService());

  group('recordFinishedMatch', () {
    test('guarda la partida terminada a nombre del jugador', () async {
      final stats = await controllerFor(_profile);

      final ok = await stats.recordFinishedMatch(
        roomId: 'sala-1',
        game: _game(GamePhase.finished),
        tracker: MatchTimeTracker(clock: () => now),
        isHost: true,
        isPublic: true,
      );

      expect(ok, isTrue);
      expect(service.recordedMatches, hasLength(1));
      final (uid, match) = service.recordedMatches.single;
      expect(uid, 'uid-1');
      expect(match.matchId, 'sala-1');
      expect(match.won, isTrue);
      expect(match.isHost, isTrue);
      expect(match.isPublic, isTrue);
      expect(match.opponents, {'uid-2': 'Beto'});
      expect(match.playedWithFriend, isTrue);
    });

    test('no guarda nada si la partida no ha terminado', () async {
      final stats = await controllerFor(_profile);

      final ok = await stats.recordFinishedMatch(
        roomId: 'sala-1',
        game: _game(GamePhase.rolling),
        tracker: MatchTimeTracker(),
      );

      expect(ok, isFalse);
      expect(service.recordedMatches, isEmpty);
    });

    test('un error del servicio no se lanza: devuelve false', () async {
      final stats = await controllerFor(_profile);
      service.nextError = Exception('sin conexión');

      final ok = await stats.recordFinishedMatch(
        roomId: 'sala-1',
        game: _game(GamePhase.finished),
        tracker: MatchTimeTracker(),
      );

      expect(ok, isFalse);
    });
  });

  group('addAppTime', () {
    test('guarda el tiempo del jugador', () async {
      final stats = await controllerFor(_profile);

      await stats.addAppTime(const Duration(minutes: 2));

      expect(service.appTimes, [('uid-1', const Duration(minutes: 2))]);
    });

    test('ignora tiempos de menos de un segundo', () async {
      final stats = await controllerFor(_profile);

      final ok = await stats.addAppTime(const Duration(milliseconds: 300));

      expect(ok, isFalse);
      expect(service.appTimes, isEmpty);
    });
  });

  test('registerActivity usa la hora del reloj', () async {
    final stats = await controllerFor(_profile);

    await stats.registerActivity();

    expect(service.activities, [('uid-1', now)]);
  });

  test('recordSocial suma el contador del jugador', () async {
    final stats = await controllerFor(_profile);

    await stats.recordSocial(SocialCounter.messageSent);

    expect(service.socialCounters, [('uid-1', SocialCounter.messageSent)]);
  });

  test('sin sesión no guarda nada', () async {
    final stats = await controllerFor(null);

    expect(await stats.addAppTime(const Duration(minutes: 1)), isFalse);
    expect(await stats.registerActivity(), isFalse);
    expect(await stats.recordSocial(SocialCounter.inviteSent), isFalse);
    expect(service.appTimes, isEmpty);
    expect(service.activities, isEmpty);
    expect(service.socialCounters, isEmpty);
  });
}
