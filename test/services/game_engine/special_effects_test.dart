import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'package:party_tricks/services/game_engine/tile_effects.dart';

import 'fake_random_source.dart';
import 'test_board.dart';

// En el tablero de prueba la 1 y la 2 son positivas (+3), la 5 también.

GameEngine engineWith(List<int> randomValues) {
  return GameEngine(
    board: buildTestBoard(),
    random: FakeRandomSource(randomValues),
  );
}

PlayerState beto(
  PendingEffect? effect, {
  int coins = 10,
  int diamonds = 0,
  Map<ShopItem, int> inventory = const {},
}) {
  return PlayerState(
    id: 'b',
    username: 'Beto',
    coins: coins,
    diamonds: diamonds,
    inventory: inventory,
    pendingEffect: effect,
  );
}

GameState game(PlayerState beto, {int anaCoins = 10}) {
  return GameState(
    players: {
      'b': beto,
      'a': PlayerState(id: 'a', username: 'Ana', coins: anaCoins),
    },
    turnOrder: const ['b', 'a'],
    totalRounds: 5,
    diamondTileId: 41,
  );
}

/// El número del sorteo (1 a totalWeight) con el que sale [effect].
int rollFor(PendingEffect effect) {
  var before = 0;
  for (final e in PendingEffect.values) {
    if (e == effect) return before + 1;
    before += e.weight;
  }
  throw ArgumentError(effect);
}

void main() {
  group('el sorteo', () {
    test('cada efecto sale con su número y con el último de su rango', () {
      var before = 0;
      for (final effect in PendingEffect.values) {
        expect(PendingEffect.forRoll(before + 1), effect);
        expect(PendingEffect.forRoll(before + effect.weight), effect);
        before += effect.weight;
      }
      expect(before, PendingEffect.totalWeight);
    });

    test('hay buenos, malos y neutros, y más malos que antes', () {
      int count(EffectKind kind) =>
          PendingEffect.values.where((e) => e.kind == kind).length;
      expect(count(EffectKind.bad), 6);
      expect(count(EffectKind.good), 6);
      expect(count(EffectKind.neutral), 2);
      // Los malos pesan un poco más que los buenos.
      int weight(EffectKind kind) => PendingEffect.values
          .where((e) => e.kind == kind)
          .fold(0, (sum, e) => sum + e.weight);
      expect(weight(EffectKind.bad), greaterThan(weight(EffectKind.good)));
    });

    test('todos tienen nombre y descripción', () {
      for (final effect in PendingEffect.values) {
        expect(effect.title, isNotEmpty);
        expect(effect.description, isNotEmpty);
      }
    });
  });

  group('efectos buenos', () {
    test('Viento a favor: avanza 3 casillas más', () {
      final state = engineWith([
        2,
      ]).apply(game(beto(PendingEffect.boost)), const RollDice('b'));
      expect(state.lastRoll, 2);
      expect(state.lastBoost, 3);
      expect(state.players['b']!.position, 5);
      expect(state.players['b']!.pendingEffect, isNull);
    });

    test('Escudo de regalo: lo guarda en la mochila, hasta 3', () {
      var state = engineWith([
        1,
      ]).apply(game(beto(PendingEffect.freeShield)), const RollDice('b'));
      expect(state.players['b']!.itemCount(ShopItem.shield), 1);

      state = engineWith([1]).apply(
        game(beto(PendingEffect.freeShield, inventory: {ShopItem.shield: 3})),
        const RollDice('b'),
      );
      expect(state.players['b']!.itemCount(ShopItem.shield), 3);
    });

    test('Ítem sorpresa: da uno al azar que le quepa', () {
      var state = engineWith([
        0,
        1,
      ]).apply(game(beto(PendingEffect.freeItem)), const RollDice('b'));
      expect(state.players['b']!.itemCount(ShopItem.extraDie3), 1);

      // Con tres dados de 3 ya no le caben: sale el siguiente.
      state = engineWith([0, 1]).apply(
        game(beto(PendingEffect.freeItem, inventory: {ShopItem.extraDie3: 3})),
        const RollDice('b'),
      );
      expect(state.players['b']!.itemCount(ShopItem.extraDie3), 3);
      expect(state.players['b']!.itemCount(ShopItem.extraDie6), 1);
    });

    test('Diamante de regalo: suma un diamante', () {
      final state = engineWith([1]).apply(
        game(beto(PendingEffect.diamondGift, diamonds: 2)),
        const RollDice('b'),
      );
      expect(state.players['b']!.diamonds, 3);
    });

    test('Dado de 12 y Lluvia de monedas siguen funcionando', () {
      var state = engineWith([
        12,
      ]).apply(game(beto(PendingEffect.die12)), const RollDice('b'));
      expect(state.lastRoll, 12);

      state = engineWith([
        1,
      ]).apply(game(beto(PendingEffect.gainCoins)), const RollDice('b'));
      // +5 del efecto y +3 de la casilla 1.
      expect(state.players['b']!.coins, 18);
    });
  });

  group('efectos malos', () {
    test('Dado de 2: el dado solo llega a 2', () {
      final state = engineWith([
        2,
      ]).apply(game(beto(PendingEffect.die2)), const RollDice('b'));
      expect(state.lastRoll, 2);
      expect(state.players['b']!.position, 2);
    });

    test('Dado de 2: un número mayor no es posible', () {
      expect(
        () => engineWith([
          3,
        ]).apply(game(beto(PendingEffect.die2)), const RollDice('b')),
        throwsArgumentError,
      );
    });

    test('Pierdes el turno: no lanza y pasa al siguiente', () {
      final state = engineWith(
        [],
      ).apply(game(beto(PendingEffect.skipTurn)), const RollDice('b'));
      expect(state.currentPlayerId, 'a');
      expect(state.phase, GamePhase.rolling);
      expect(state.players['b']!.pendingEffect, isNull);
      expect(state.players['b']!.diceRolled, 0);
      expect(state.players['b']!.position, 0);
    });

    test('Pierdes el turno: en la siguiente ronda sí lanza', () {
      final engine = engineWith([1, 1, 1]);
      var state = engine.apply(
        game(beto(PendingEffect.skipTurn)),
        const RollDice('b'),
      );
      state = engine.apply(state, const RollDice('a'));
      state = engine.apply(state, const FinishMinigame(['a']));
      state = engine.apply(state, const RollDice('b'));
      expect(state.players['b']!.position, 1);
    });

    test('Se te cae un ítem: pierde uno al azar de la mochila', () {
      final state = engineWith([0, 1]).apply(
        game(
          beto(
            PendingEffect.loseItem,
            inventory: {ShopItem.trap: 2, ShopItem.shield: 1},
          ),
        ),
        const RollDice('b'),
      );
      // Los ítems se ordenan como en el catálogo: la trampa va primero.
      expect(state.players['b']!.itemCount(ShopItem.trap), 1);
      expect(state.players['b']!.itemCount(ShopItem.shield), 1);
      expect(state.players['b']!.itemsUsed, 0, reason: 'no cuenta como usado');
    });

    test('Se te cae un ítem: con la mochila vacía no pasa nada', () {
      final state = engineWith([
        1,
      ]).apply(game(beto(PendingEffect.loseItem)), const RollDice('b'));
      expect(state.players['b']!.inventory, isEmpty);
    });

    test('Paga la cuenta de la fiesta: le da monedas a cada rival', () {
      final state = engineWith([
        1,
      ]).apply(game(beto(PendingEffect.payEveryone)), const RollDice('b'));
      // Paga 2 a Ana y cobra +3 de la casilla 1.
      expect(state.players['b']!.coins, 11);
      expect(state.players['a']!.coins, 12);
    });

    test('Paga la cuenta de la fiesta: no da más de lo que tiene', () {
      final state = engineWith([1]).apply(
        game(beto(PendingEffect.payEveryone, coins: 1)),
        const RollDice('b'),
      );
      expect(state.players['b']!.coins, 3, reason: '0 tras pagar + 3');
      expect(state.players['a']!.coins, 11);
    });

    test('Se esfuman las monedas: nunca baja de cero', () {
      final state = engineWith([1]).apply(
        game(beto(PendingEffect.loseCoins, coins: 2)),
        const RollDice('b'),
      );
      // 0 tras perder y +3 de la casilla.
      expect(state.players['b']!.coins, 3);
    });
  });

  group('efectos neutros', () {
    test('Cambio de monedas: intercambia con un rival al azar', () {
      final state = engineWith([0, 1]).apply(
        game(beto(PendingEffect.coinSwap), anaCoins: 20),
        const RollDice('b'),
      );
      // Beto queda con las 20 de Ana (y +3 de la casilla); Ana con las 10.
      expect(state.players['b']!.coins, 23);
      expect(state.players['a']!.coins, 10);
    });

    test('Regreso al inicio: vuelve a la salida antes de lanzar', () {
      final engine = engineWith([2]);
      final state = engine.apply(
        game(beto(PendingEffect.backToStart).copyWith(position: 9)),
        const RollDice('b'),
      );
      expect(state.players['b']!.position, 2);
    });
  });

  test('un efecto guardado que esta versión no conoce se ignora', () {
    expect(PendingEffect.values.asNameMap()['inventado'], isNull);
  });

  test('rollFor coincide con el sorteo real', () {
    for (final effect in PendingEffect.values) {
      expect(PendingEffect.forRoll(rollFor(effect)), effect);
    }
  });
}
