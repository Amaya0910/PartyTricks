import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/rooms/disconnection_policy.dart';

import 'fake_room_services.dart';

GameState game(String current, GamePhase phase) {
  return GameState(
    players: const {
      'host': PlayerState(id: 'host', username: 'Host'),
      'ana': PlayerState(id: 'ana', username: 'Ana'),
      'beto': PlayerState(id: 'beto', username: 'Beto'),
    },
    turnOrder: const ['host', 'ana', 'beto'],
    turnIndex: ['host', 'ana', 'beto'].indexOf(current),
    totalRounds: 5,
    diamondTileId: 1,
    phase: phase,
  );
}

void main() {
  const policy = DisconnectionPolicy();

  group('cambio de anfitrión', () {
    test('si el anfitrión está conectado, sigue siendo él', () {
      expect(policy.successorFor(testRoom(), testNow), isNull);
    });

    test('se le espera un rato antes de reemplazarlo', () {
      final room = testRoom(host: hostAway(const Duration(seconds: 5)));
      expect(policy.successorFor(room, testNow), isNull);
    });

    test('pasado el tiempo, lo reemplaza el conectado que llegó primero', () {
      final room = testRoom(host: hostAway(const Duration(seconds: 20)));
      expect(policy.successorFor(room, testNow), 'ana');

      final anaAway = testRoom(
        host: hostAway(const Duration(seconds: 20)),
        anaConnected: false,
      );
      expect(policy.successorFor(anaAway, testNow), 'beto');
    });

    test('si el anfitrión salió de la sala, se reemplaza enseguida', () {
      expect(policy.successorFor(testRoom(hostPresent: false), testNow), 'ana');
    });

    test('si no queda nadie conectado, no hay sucesor', () {
      final room = testRoom(
        hostPresent: false,
        anaConnected: false,
        betoConnected: false,
      );
      expect(policy.successorFor(room, testNow), isNull);
    });

    test('nunca espera menos de lo que piden las reglas', () {
      const hurried = DisconnectionPolicy(hostTimeout: Duration(seconds: 1));
      final room = testRoom(host: hostAway(const Duration(seconds: 5)));
      expect(hurried.successorFor(room, testNow), isNull);
      final later = testRoom(host: hostAway(const Duration(seconds: 11)));
      expect(hurried.successorFor(later, testNow), 'ana');
    });

    test('el tiempo de espera se puede cambiar', () {
      const patient = DisconnectionPolicy(hostTimeout: Duration(minutes: 1));
      final room = testRoom(host: hostAway(const Duration(seconds: 30)));
      expect(patient.successorFor(room, testNow), isNull);
    });
  });

  group('saltar turno', () {
    test('se salta el turno de quien lleva desconectado', () {
      final room = testRoom(anaConnected: false);
      for (final phase in [
        GamePhase.rolling,
        GamePhase.choosingBranch,
        GamePhase.shopping,
      ]) {
        expect(
          policy.shouldSkipTurn(room, game('ana', phase), testNow),
          isTrue,
          reason: phase.name,
        );
      }
    });

    test('no en el minijuego, al terminar ni si está conectado', () {
      final room = testRoom(anaConnected: false);
      expect(
        policy.shouldSkipTurn(room, game('ana', GamePhase.minigame), testNow),
        isFalse,
      );
      expect(
        policy.shouldSkipTurn(room, game('ana', GamePhase.finished), testNow),
        isFalse,
      );
      expect(
        policy.shouldSkipTurn(
          testRoom(),
          game('ana', GamePhase.shopping),
          testNow,
        ),
        isFalse,
      );
    });

    test('se espera el tiempo configurado antes de saltarlo', () {
      final room = testRoom(anaConnected: false);
      final justLeft = testNow.subtract(const Duration(hours: 1));
      // testRoom marca a Ana desconectada a las 19:00; a las 19:00:10 aún
      // no se salta con 30 s de espera.
      expect(
        policy.shouldSkipTurn(
          room,
          game('ana', GamePhase.rolling),
          justLeft.add(const Duration(seconds: 10)),
        ),
        isFalse,
      );
    });
  });

  group('tiempo máximo por turno', () {
    test('el turno dura 40 segundos', () {
      expect(policy.turnTimeout, const Duration(seconds: 40));
    });

    test('se salta a quien sigue conectado pero no hace nada', () {
      final started = testNow;
      for (final phase in [
        GamePhase.rolling,
        GamePhase.choosingBranch,
        GamePhase.shopping,
      ]) {
        final turn = game('ana', phase);
        expect(
          policy.shouldSkipTurn(
            testRoom(),
            turn,
            started.add(const Duration(seconds: 39)),
            turnStartedAt: started,
          ),
          isFalse,
          reason: '${phase.name} a los 39 s',
        );
        expect(
          policy.shouldSkipTurn(
            testRoom(),
            turn,
            started.add(const Duration(seconds: 40)),
            turnStartedAt: started,
          ),
          isTrue,
          reason: '${phase.name} a los 40 s',
        );
      }
    });

    test('no cuenta en el minijuego ni al terminar', () {
      final started = testNow;
      final later = started.add(const Duration(minutes: 5));
      for (final phase in [GamePhase.minigame, GamePhase.finished]) {
        expect(
          policy.shouldSkipTurn(
            testRoom(),
            game('ana', phase),
            later,
            turnStartedAt: started,
          ),
          isFalse,
          reason: phase.name,
        );
      }
    });
  });

  group('quedarse solo', () {
    test('solo si todos los demás salieron o llevan desconectados', () {
      final turn = game('host', GamePhase.rolling);
      expect(
        policy.isAlone(
          testRoom(anaConnected: false, betoConnected: false),
          turn,
          'host',
          testNow,
        ),
        isTrue,
      );
      expect(
        policy.isAlone(testRoom(anaConnected: false), turn, 'host', testNow),
        isFalse,
        reason: 'Beto sigue conectado',
      );
    });

    test('quien salió de la sala cuenta como ido', () {
      final room = Room(
        id: 'sala',
        code: 'ABC234',
        isPublic: false,
        hostUid: 'host',
        maxPlayers: 4,
        rounds: 5,
        status: RoomStatus.playing,
        lobbyEndsAt: testNow,
        players: {
          'host': RoomPlayer(uid: 'host', username: 'Host', joinedAt: testNow),
        },
      );
      expect(
        policy.isAlone(room, game('host', GamePhase.rolling), 'host', testNow),
        isTrue,
      );
    });

    test('un desconectado reciente puede volver: aún no está solo', () {
      final room = testRoom(anaConnected: false, betoConnected: false);
      // testRoom los marca desconectados a las 19:00.
      final soon = DateTime(2026, 10, 28, 19, 0, 10);
      expect(
        policy.isAlone(room, game('host', GamePhase.rolling), 'host', soon),
        isFalse,
      );
    });

    test('no al terminar la partida ni si el propio jugador no está', () {
      final room = testRoom(anaConnected: false, betoConnected: false);
      expect(
        policy.isAlone(room, game('host', GamePhase.finished), 'host', testNow),
        isFalse,
      );
      expect(
        policy.isAlone(
          testRoom(
            hostPresent: false,
            anaConnected: false,
            betoConnected: false,
          ),
          game('ana', GamePhase.rolling),
          'host',
          testNow,
        ),
        isFalse,
      );
    });
  });

  group('salas abandonadas', () {
    test('con alguien conectado nunca está abandonada', () {
      final old = testNow.subtract(const Duration(days: 3));
      expect(policy.isAbandoned(testRoom(lastActiveAt: old), testNow), isFalse);
    });

    test('sin nadie conectado, se cuenta desde la última señal', () {
      Room empty(DateTime? lastActiveAt) => testRoom(
        hostPresent: false,
        anaConnected: false,
        betoConnected: false,
        lastActiveAt: lastActiveAt,
      );
      expect(
        policy.isAbandoned(
          empty(testNow.subtract(const Duration(minutes: 30))),
          testNow,
        ),
        isFalse,
      );
      expect(
        policy.isAbandoned(
          empty(testNow.subtract(const Duration(hours: 3))),
          testNow,
        ),
        isTrue,
      );
      // Sin señales del anfitrión, cuenta desde que terminó la espera.
      expect(
        policy.isAbandoned(empty(null), DateTime(2026, 10, 28, 22)),
        isTrue,
      );
    });

    test('no baja de lo que exigen las reglas', () {
      const eager = DisconnectionPolicy(abandonedAfter: Duration(minutes: 1));
      final room = testRoom(
        hostPresent: false,
        anaConnected: false,
        betoConnected: false,
        lastActiveAt: testNow.subtract(const Duration(minutes: 10)),
      );
      expect(eager.isAbandoned(room, testNow), isFalse);
    });
  });

  test('la sala guarda y lee lastSeen y lastActiveAt', () {
    final seen = DateTime(2026, 10, 28, 19, 30);
    final room = Room.fromMap('sala', {
      'meta': {...testRoom(lastActiveAt: seen).metaToMap()},
      'players': {
        'ana': RoomPlayer(
          uid: 'ana',
          username: 'Ana',
          joinedAt: seen,
          connected: false,
          lastSeen: seen,
        ).toMap(),
        // Jugador guardado antes de la presencia: sin lastSeen.
        'beto': {'username': 'Beto', 'joinedAt': 1},
      },
    });

    expect(room.lastActiveAt, seen);
    expect(room.players['ana']!.lastSeen, seen);
    expect(room.players['ana']!.connected, isFalse);
    expect(room.players['beto']!.lastSeen, isNull);
    expect(room.players['beto']!.connected, isTrue);
    expect(testRoom().metaToMap().containsKey('lastActiveAt'), isFalse);
  });
}
