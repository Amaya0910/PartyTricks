import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/tile_effects.dart';
import 'package:party_tricks/services/game_engine/turn_order_resolver.dart';

import 'fake_random_source.dart';

/// En la tirada inicial Beto saca más, así que juega primero.
const rolls = [
  InitialRoll(playerId: 'a', username: 'Ana', value: 3),
  InitialRoll(playerId: 'b', username: 'Beto', value: 5),
];

/// Con este valor el diamante empieza en la casilla 41, lejos de la salida.
const diamondFar = 38;

GameEngine engineWith(List<int> randomValues) {
  return GameEngine(
    board: buildDefaultBoard(),
    random: FakeRandomSource(randomValues),
  );
}

void main() {
  test('empieza con el orden de la tirada inicial', () {
    final engine = engineWith([diamondFar]);
    final state = engine.start(initialRolls: rolls, totalRounds: 2);

    expect(state.turnOrder, ['b', 'a']);
    expect(state.currentPlayerId, 'b');
    expect(state.round, 1);
    expect(state.phase, GamePhase.rolling);
    expect(state.diamondTileId, 41);
    expect(state.players['a']!.coins, 10);
    expect(state.players['a']!.position, BoardLayout.startId);
  });

  test('al caer en una positiva gana monedas y pasa el turno', () {
    final engine = engineWith([diamondFar, 2]);
    var state = engine.start(initialRolls: rolls, totalRounds: 2);
    state = engine.apply(state, const RollDice('b'));

    expect(state.lastRoll, 2);
    expect(state.players['b']!.position, 2);
    expect(state.players['b']!.coins, 13);
    expect(state.currentPlayerId, 'a');
  });

  test('las monedas nunca bajan de cero', () {
    const player = PlayerState(id: 'a', username: 'Ana', coins: 2);
    expect(player.addCoins(-5).coins, 0);
  });

  test('se detiene en la bifurcación y sigue por el camino elegido', () {
    final engine = engineWith([diamondFar, 6]);
    var state = engine.start(initialRolls: rolls, totalRounds: 2);
    state = engine.apply(state, const RollDice('b'));

    expect(state.phase, GamePhase.choosingBranch);
    expect(state.players['b']!.position, 5);
    expect(state.stepsLeft, 1);

    state = engine.apply(state, const ChooseBranch('b', 1));
    expect(state.players['b']!.position, 30);
    expect(state.phase, GamePhase.rolling);
    expect(state.currentPlayerId, 'a');
  });

  test('la casilla especial cambia el dado del siguiente turno', () {
    // Beto saca 3 (especial, sale el efecto 1 = dado de 12) y Ana saca 1.
    final engine = engineWith([diamondFar, 3, 1, 1, 12]);
    var state = engine.start(initialRolls: rolls, totalRounds: 2);
    state = engine.apply(state, const RollDice('b'));
    expect(state.players['b']!.pendingEffect, PendingEffect.die12);

    state = engine.apply(state, const RollDice('a'));
    state = engine.apply(state, const FinishMinigame(['a']));

    // En la ronda 2 Beto lanza el dado de 12 y saca 12.
    state = engine.apply(state, const RollDice('b'));
    expect(state.lastRoll, 12);
    expect(state.players['b']!.pendingEffect, isNull);
    expect(state.phase, GamePhase.choosingBranch);
    expect(state.stepsLeft, 10);
  });

  test('al pasar por el diamante lo gana y el diamante cambia de casilla', () {
    // El diamante empieza en la casilla 2 y reaparece en la 1.
    final engine = engineWith([1, 4, 0]);
    var state = engine.start(initialRolls: rolls, totalRounds: 2);
    expect(state.diamondTileId, 2);

    state = engine.apply(state, const RollDice('b'));
    expect(state.players['b']!.diamonds, 1);
    expect(state.players['b']!.position, 4);
    expect(state.diamondTileId, 1);
  });

  test(
    'después de los turnos viene el minijuego y en la última ronda termina',
    () {
      final engine = engineWith([diamondFar, 1, 1]);
      var state = engine.start(initialRolls: rolls, totalRounds: 1);
      state = engine.apply(state, const RollDice('b'));
      state = engine.apply(state, const RollDice('a'));
      expect(state.phase, GamePhase.minigame);

      state = engine.apply(state, const FinishMinigame(['b']));
      expect(state.phase, GamePhase.finished);
      expect(state.players['b']!.coins, 23);
      expect(state.players['b']!.minigamesWon, 1);
    },
  );

  group('contadores para las estadísticas', () {
    test('cuenta los dados, la suma y el número máximo', () {
      // Beto saca 6 (máximo) y cae en la bifurcación; Ana saca 2.
      final engine = engineWith([diamondFar, 6, 2]);
      var state = engine.start(initialRolls: rolls, totalRounds: 2);
      state = engine.apply(state, const RollDice('b'));
      state = engine.apply(state, const ChooseBranch('b', 0));
      state = engine.apply(state, const RollDice('a'));

      final beto = state.players['b']!;
      expect(beto.diceRolled, 1);
      expect(beto.diceTotal, 6);
      expect(beto.maxRolls, 1);
      final ana = state.players['a']!;
      expect(ana.diceRolled, 1);
      expect(ana.diceTotal, 2);
      expect(ana.maxRolls, 0);
    });

    test('cuenta el camino elegido en la bifurcación', () {
      final engine = engineWith([diamondFar, 6, 6]);
      var state = engine.start(initialRolls: rolls, totalRounds: 2);
      state = engine.apply(state, const RollDice('b'));
      state = engine.apply(state, const ChooseBranch('b', 0));
      state = engine.apply(state, const RollDice('a'));
      state = engine.apply(state, const ChooseBranch('a', 1));

      expect(state.players['b']!.mainPathsTaken, 1);
      expect(state.players['b']!.shortcutsTaken, 0);
      expect(state.players['a']!.shortcutsTaken, 1);
      expect(state.players['a']!.mainPathsTaken, 0);
    });

    test('cuenta el tipo de casilla donde cae', () {
      // Beto cae en la 2 (positiva); Ana en la 3 (especial, efecto 0).
      final engine = engineWith([diamondFar, 2, 3, 0]);
      var state = engine.start(initialRolls: rolls, totalRounds: 2);
      state = engine.apply(state, const RollDice('b'));
      state = engine.apply(state, const RollDice('a'));

      expect(state.players['b']!.positiveTiles, 1);
      expect(state.players['b']!.specialTiles, 0);
      expect(state.players['a']!.specialTiles, 1);
      expect(state.players['a']!.positiveTiles, 0);
    });

    test('cuenta los diamantes del mapa', () {
      // El diamante empieza en la casilla 2 y reaparece en la 1.
      final engine = engineWith([1, 4, 0]);
      var state = engine.start(initialRolls: rolls, totalRounds: 2);
      state = engine.apply(state, const RollDice('b'));

      expect(state.players['b']!.mapDiamonds, 1);
    });

    test('cuenta una vuelta al pasar por la salida', () {
      const nearEnd = PlayerState(id: 'b', username: 'Beto', position: 28);
      final engine = engineWith([3]);
      const state = GameState(
        players: {
          'b': nearEnd,
          'a': PlayerState(id: 'a', username: 'Ana'),
        },
        turnOrder: ['b', 'a'],
        totalRounds: 2,
        diamondTileId: 41,
      );

      final next = engine.apply(state, const RollDice('b'));

      expect(next.players['b']!.position, 1);
      expect(next.players['b']!.laps, 1);
    });
  });

  test('no deja jugar fuera de turno', () {
    final engine = engineWith([diamondFar]);
    final state = engine.start(initialRolls: rolls, totalRounds: 2);

    expect(() => engine.apply(state, const RollDice('a')), throwsStateError);
    expect(
      () => engine.apply(state, const FinishMinigame(['a'])),
      throwsStateError,
    );
  });
}
