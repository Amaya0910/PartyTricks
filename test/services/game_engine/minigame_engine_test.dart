import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';

import 'fake_random_source.dart';
import 'test_board.dart';

GameEngine _engine(
  List<int> randomValues, {
  List<MinigameType> minigames = MinigameType.values,
}) {
  return GameEngine(
    board: buildTestBoard(),
    random: FakeRandomSource(randomValues),
    minigames: minigames,
  );
}

/// Beto, el último del orden, está en la tienda: al salir termina la ronda.
GameState _lastTurn({
  int round = 1,
  int totalRounds = 3,
  bool caroAway = false,
}) {
  return GameState(
    players: {
      'ana': const PlayerState(id: 'ana', username: 'Ana', coins: 5),
      'caro': PlayerState(id: 'caro', username: 'Caro', away: caroAway),
      'beto': const PlayerState(id: 'beto', username: 'Beto', coins: 3),
    },
    turnOrder: const ['ana', 'caro', 'beto'],
    turnIndex: 2,
    round: round,
    totalRounds: totalRounds,
    diamondTileId: 1,
    phase: GamePhase.shopping,
  );
}

void main() {
  test('al terminar la ronda se sortea el minijuego con sus números', () {
    // Sorteo: índice 1 = Reacción; espera de 2500 ms.
    final engine = _engine([1, 2500]);
    final state = engine.apply(_lastTurn(), const LeaveShop('beto'));
    expect(state.phase, GamePhase.minigame);
    expect(state.minigame!.type, MinigameType.reaction);
    expect(state.minigame!.delayMs, 2500);
    expect(state.minigame!.round, 1);
    expect(state.minigame!.players, ['ana', 'caro', 'beto']);
  });

  test('los ausentes no juegan el minijuego', () {
    final engine = _engine([12], minigames: [MinigameType.stopwatch]);
    final state = engine.apply(
      _lastTurn(caroAway: true),
      const LeaveShop('beto'),
    );
    expect(state.minigame!.players, ['ana', 'beto']);
  });

  test('cuando juegan todos, el ganador cobra y sigue la ronda', () {
    final engine = _engine([10], minigames: [MinigameType.stopwatch]);
    var state = engine.apply(_lastTurn(), const LeaveShop('beto'));
    state = engine.apply(state, const MinigameMove('ana', 1, 9500));
    state = engine.apply(state, const MinigameMove('caro', 1, 12000));
    expect(state.phase, GamePhase.minigame, reason: 'falta Beto');
    state = engine.apply(state, const MinigameMove('beto', 1, 10100));

    expect(state.phase, GamePhase.rolling);
    expect(state.round, 2);
    expect(state.minigame, isNull);
    expect(state.lastMinigame!.winnerIds, ['beto']);
    expect(state.players['beto']!.coins, 3 + engine.minigameCoins);
    expect(state.players['beto']!.minigamesWon, 1);
    expect(state.players['ana']!.coins, 5);
  });

  test('en la última ronda, el minijuego termina la partida', () {
    final engine = _engine([3000], minigames: [MinigameType.reaction]);
    var state = engine.apply(
      _lastTurn(round: 3, totalRounds: 3),
      const LeaveShop('beto'),
    );
    for (final (i, id) in ['ana', 'caro', 'beto'].indexed) {
      state = engine.apply(state, MinigameMove(id, 3, 300 + i));
    }
    expect(state.phase, GamePhase.finished);
  });

  test('las jugadas de otra ronda o fuera del minijuego no valen', () {
    final engine = _engine([10], minigames: [MinigameType.stopwatch]);
    expect(
      () => engine.apply(_lastTurn(), const MinigameMove('ana', 1, 9000)),
      throwsStateError,
    );
    final state = engine.apply(_lastTurn(), const LeaveShop('beto'));
    expect(
      () => engine.apply(state, const MinigameMove('ana', 2, 9000)),
      throwsStateError,
    );
    expect(
      () => engine.apply(state, const MinigameTimeout(1, 5)),
      throwsStateError,
    );
  });

  test('el cierre por tiempo decide con los que jugaron', () {
    final engine = _engine([3000], minigames: [MinigameType.reaction]);
    var state = engine.apply(_lastTurn(), const LeaveShop('beto'));
    state = engine.apply(state, const MinigameMove('caro', 1, 280));
    state = engine.apply(state, MinigameTimeout(1, state.minigame!.step));
    expect(state.round, 2);
    expect(state.lastMinigame!.winnerIds, ['caro']);
    expect(state.lastMinigame!.scores['ana'], MinigameRules.noScore);
  });

  test(
    'un jugador marcado ausente que vuelve y juega deja de estar ausente',
    () {
      final engine = _engine([10], minigames: [MinigameType.stopwatch]);
      final start = engine.apply(_lastTurn(), const LeaveShop('beto'));
      // Se cayó durante el minijuego y el anfitrión lo marcó, pero sigue en
      // la lista de este minijuego: al volver puede jugar.
      final marked = start.withPlayer(
        start.players['ana']!.copyWith(away: true),
      );
      final state = engine.apply(marked, const MinigameMove('ana', 1, 9900));
      expect(state.players['ana']!.away, isFalse);
      expect(state.minigame!.scores['ana'], 9900);
    },
  );

  test('el desempate con el dado le da las monedas a uno solo', () {
    final engine = _engine([3000, 2, 5], minigames: [MinigameType.reaction]);
    var state = engine.apply(_lastTurn(), const LeaveShop('beto'));
    state = engine.apply(state, const MinigameMove('ana', 1, 300));
    state = engine.apply(state, const MinigameMove('caro', 1, 300));
    state = engine.apply(state, const MinigameMove('beto', 1, 900));
    expect(state.lastMinigame!.winnerIds, ['caro']);
    expect(state.players['caro']!.coins, engine.minigameCoins);
    expect(state.players['ana']!.coins, 5);
  });

  test('Globo Bomba: el último vivo gana y cobra', () {
    final engine = _engine([30, 30], minigames: [MinigameType.balloon]);
    var state = engine.apply(_lastTurn(), const LeaveShop('beto'));
    state = state.copyWith(minigame: state.minigame!.copyWith(pumps: 29));
    state = engine.apply(state, const MinigameMove('ana', 1, 1)); // Revienta.
    state = state.copyWith(minigame: state.minigame!.copyWith(pumps: 29));
    state = engine.apply(state, const MinigameMove('caro', 1, 3)); // Revienta.
    expect(state.round, 2);
    expect(state.lastMinigame!.winnerIds, ['beto']);
    expect(state.lastMinigame!.out, ['ana', 'caro']);
    expect(state.players['beto']!.coins, 3 + engine.minigameCoins);
  });

  test('sin minijuegos configurados se espera FinishMinigame, como antes', () {
    final engine = _engine([], minigames: const []);
    final state = engine.apply(_lastTurn(), const LeaveShop('beto'));
    expect(state.phase, GamePhase.minigame);
    expect(state.minigame, isNull);
    final next = engine.apply(state, const FinishMinigame(['ana']));
    expect(next.players['ana']!.coins, 5 + engine.minigameCoins);
  });

  test(
    'partida vieja sin minijuego armado: el cierre por tiempo la destraba',
    () {
      final engine = _engine([]);
      final old = _lastTurn().copyWith(phase: GamePhase.minigame);
      final next = engine.apply(old, const MinigameTimeout(1, 0));
      expect(next.phase, GamePhase.rolling);
      expect(next.round, 2);
    },
  );

  group('guardado en la base de datos', () {
    const codec = GameCodec();

    test('el minijuego en curso y el último resultado se leen igual', () {
      final engine = _engine([3000], minigames: [MinigameType.reaction]);
      var state = engine.apply(_lastTurn(), const LeaveShop('beto'));
      state = engine.apply(state, const MinigameMove('ana', 1, 410));
      final read = codec.decodeState(codec.encodeState(state));
      expect(read.minigame!.type, MinigameType.reaction);
      expect(read.minigame!.delayMs, 3000);
      expect(read.minigame!.scores, {'ana': 410});
      expect(read.minigame!.step, 1);
      expect(read.minigame!.players, ['ana', 'caro', 'beto']);

      final balloon = MinigameState(
        type: MinigameType.balloon,
        round: 2,
        players: const ['ana', 'beto', 'caro'],
        capacity: 44,
        pumps: 7,
        turn: 2,
        step: 3,
        out: const ['beto'],
      );
      final readBalloon = codec
          .decodeState(codec.encodeState(state.copyWith(minigame: balloon)))
          .minigame!;
      expect(readBalloon.capacity, 44);
      expect(readBalloon.pumps, 7);
      expect(readBalloon.balloonPlayer, 'caro');
      expect(readBalloon.out, ['beto']);

      final result = MinigameResult(
        type: MinigameType.stopwatch,
        round: 1,
        winnerIds: const ['ana'],
        targetMs: 9000,
        scores: const {'ana': 9100, 'beto': MinigameRules.noScore},
        tiebreak: const {
          'ana': [6],
          'beto': [2],
        },
      );
      final readResult = codec
          .decodeState(codec.encodeState(state.copyWith(lastMinigame: result)))
          .lastMinigame!;
      expect(readResult.winnerIds, ['ana']);
      expect(readResult.targetMs, 9000);
      expect(readResult.scores, result.scores);
      expect(readResult.tiebreak, result.tiebreak);
    });

    test('las acciones del minijuego se leen igual', () {
      final move =
          codec.decodeAction(
                codec.encodeAction(const MinigameMove('ana', 3, 1234)),
              )
              as MinigameMove;
      expect((move.playerId, move.round, move.score), ('ana', 3, 1234));
      final timeout =
          codec.decodeAction(codec.encodeAction(const MinigameTimeout(3, 4)))
              as MinigameTimeout;
      expect((timeout.round, timeout.step), (3, 4));
    });

    test('una partida guardada antes de los minijuegos se sigue leyendo', () {
      final data = codec.encodeState(_lastTurn())
        ..remove('minigame')
        ..remove('lastMinigame');
      final read = codec.decodeState(data);
      expect(read.minigame, isNull);
      expect(read.lastMinigame, isNull);
    });

    test('un minijuego que esta versión no conoce se lee como ninguno', () {
      final data = codec.encodeState(_lastTurn())
        ..['minigame'] = {'type': 'carreraNueva', 'round': 1};
      expect(codec.decodeState(data).minigame, isNull);
    });
  });
}
