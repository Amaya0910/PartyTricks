import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'test_board.dart';

import 'fake_random_source.dart';

// En el tablero de prueba las tiendas son la 12 y la 22, la 7 es negativa y
// la 2, la 4, la 10 y la 13 son positivas.

GameEngine engineWith(List<int> randomValues) {
  return GameEngine(
    board: buildTestBoard(),
    random: FakeRandomSource(randomValues),
  );
}

/// Beto juega primero. El diamante está lejos (casilla 41).
GameState game({
  PlayerState beto = const PlayerState(id: 'b', username: 'Beto', coins: 10),
  PlayerState ana = const PlayerState(id: 'a', username: 'Ana', coins: 10),
  GamePhase phase = GamePhase.rolling,
  Map<int, String> traps = const {},
  int diamondTileId = 41,
}) {
  return GameState(
    players: {'b': beto, 'a': ana},
    turnOrder: const ['b', 'a'],
    totalRounds: 5,
    diamondTileId: diamondTileId,
    phase: phase,
    traps: traps,
  );
}

PlayerState beto({
  int position = 0,
  int coins = 10,
  Map<ShopItem, int> inventory = const {},
}) {
  return PlayerState(
    id: 'b',
    username: 'Beto',
    position: position,
    coins: coins,
    inventory: inventory,
  );
}

void main() {
  group('entrar a la tienda', () {
    test('al caer en una tienda empieza a comprar y no pasa el turno', () {
      final engine = engineWith([2]);
      final state = engine.apply(
        game(beto: beto(position: 10)),
        const RollDice('b'),
      );

      expect(state.players['b']!.position, 12);
      expect(state.phase, GamePhase.shopping);
      expect(state.currentPlayerId, 'b');
    });

    test('al pasar por encima de una tienda no compra y pasa el turno', () {
      final engine = engineWith([3]);
      final state = engine.apply(
        game(beto: beto(position: 10)),
        const RollDice('b'),
      );

      expect(state.players['b']!.position, 13);
      expect(state.phase, GamePhase.rolling);
      expect(state.currentPlayerId, 'a');
    });

    test('después de una bifurcación también entra si cae en la tienda', () {
      // Desde la 4 avanza 5 + 3 (impulso): 1 paso hasta la bifurcación 5 y
      // 7 más por el principal.
      final engine = engineWith([5]);
      var state = game(
        beto: beto(position: 4, inventory: {ShopItem.movementBoost: 1}),
      );
      state = engine.apply(state, const UseItem('b', ShopItem.movementBoost));
      state = engine.apply(state, const RollDice('b'));
      expect(state.phase, GamePhase.choosingBranch);
      expect(state.stepsLeft, 7);

      state = engine.apply(state, const ChooseBranch('b', 0));
      expect(state.players['b']!.position, 12);
      expect(state.phase, GamePhase.shopping);
    });

    test('salir de la tienda pasa el turno', () {
      final engine = engineWith([]);
      final state = engine.apply(
        game(phase: GamePhase.shopping),
        const LeaveShop('b'),
      );

      expect(state.phase, GamePhase.rolling);
      expect(state.currentPlayerId, 'a');
    });

    test('si el último del turno sale de la tienda, viene el minijuego', () {
      final engine = engineWith([]);
      final state = engine.apply(
        game(phase: GamePhase.shopping).copyWith(turnIndex: 1),
        const LeaveShop('a'),
      );

      expect(state.phase, GamePhase.minigame);
    });
  });

  group('comprar', () {
    test('cobra el precio, guarda el ítem y cuenta la compra', () {
      final engine = engineWith([]);
      var state = game(phase: GamePhase.shopping);
      state = engine.apply(state, const BuyItem('b', ShopItem.shield));
      state = engine.apply(state, const BuyItem('b', ShopItem.extraDie3));

      final player = state.players['b']!;
      expect(player.coins, 10 - 5 - 4);
      expect(player.itemCount(ShopItem.shield), 1);
      expect(player.itemCount(ShopItem.extraDie3), 1);
      expect(player.purchases, 2);
      expect(state.phase, GamePhase.shopping);
    });

    test('no deja comprar sin monedas suficientes', () {
      final engine = engineWith([]);
      final state = game(beto: beto(coins: 8), phase: GamePhase.shopping);

      expect(
        engine.whyCannotBuy(state, ShopItem.extraDie9),
        'No te alcanzan las monedas',
      );
      expect(
        () => engine.apply(state, const BuyItem('b', ShopItem.extraDie9)),
        throwsStateError,
      );
    });

    test('no deja pasar del máximo de cada ítem', () {
      final engine = engineWith([]);
      final state = game(
        beto: beto(coins: 50, inventory: {ShopItem.trap: 3}),
        phase: GamePhase.shopping,
      );

      expect(engine.whyCannotBuy(state, ShopItem.trap), 'Ya tienes 3');
      expect(
        () => engine.apply(state, const BuyItem('b', ShopItem.trap)),
        throwsStateError,
      );
      expect(engine.whyCannotBuy(state, ShopItem.shield), isNull);
    });

    test('solo compra quien está en la tienda', () {
      final engine = engineWith([]);

      expect(
        () => engine.apply(game(), const BuyItem('b', ShopItem.shield)),
        throwsStateError,
      );
      expect(
        () => engine.apply(
          game(phase: GamePhase.shopping),
          const BuyItem('a', ShopItem.shield),
        ),
        throwsStateError,
      );
      expect(
        () => engine.apply(game(), const LeaveShop('b')),
        throwsStateError,
      );
    });
  });

  group('dado extra e impulso', () {
    test('el dado extra se suma al normal y se gasta', () {
      // Dado normal 2, dado extra 2: avanza 4.
      final engine = engineWith([2, 2]);
      var state = game(beto: beto(inventory: {ShopItem.extraDie3: 2}));
      state = engine.apply(state, const UseItem('b', ShopItem.extraDie3));
      expect(state.players['b']!.activeItems, [ShopItem.extraDie3]);
      expect(state.players['b']!.itemCount(ShopItem.extraDie3), 1);
      expect(state.phase, GamePhase.rolling);

      state = engine.apply(state, const RollDice('b'));

      final player = state.players['b']!;
      expect(player.position, 4);
      expect(state.lastRoll, 2);
      expect(state.lastExtraRoll, 2);
      expect(player.activeItems, isEmpty);
      expect(player.itemsUsed, 1);
      // Las estadísticas de dados solo cuentan el normal.
      expect(player.diceTotal, 2);
    });

    test('el impulso suma casillas y se combina con el dado extra', () {
      // 1 + 3 (dado extra de 3) + 3 (impulso) = 7.
      final engine = engineWith([1, 3]);
      var state = game(
        beto: beto(
          position: 3,
          inventory: {ShopItem.extraDie3: 1, ShopItem.movementBoost: 1},
        ),
      );
      state = engine.apply(state, const UseItem('b', ShopItem.extraDie3));
      state = engine.apply(state, const UseItem('b', ShopItem.movementBoost));
      state = engine.apply(state, const RollDice('b'));

      // De la 3 a la bifurcación 5 (2 pasos) y espera con 5 pendientes.
      expect(state.phase, GamePhase.choosingBranch);
      expect(state.stepsLeft, 5);
      expect(state.lastBoost, 3);
      expect(state.players['b']!.inventory, isEmpty);
    });

    test('solo un dado extra y un impulso por tirada', () {
      final engine = engineWith([]);
      var state = game(
        beto: beto(
          inventory: {
            ShopItem.extraDie3: 1,
            ShopItem.extraDie9: 1,
            ShopItem.movementBoost: 2,
          },
        ),
      );
      state = engine.apply(state, const UseItem('b', ShopItem.extraDie3));
      state = engine.apply(state, const UseItem('b', ShopItem.movementBoost));

      expect(
        engine.whyCannotUse(state, ShopItem.extraDie9),
        'Ya tienes uno activo',
      );
      expect(
        () => engine.apply(state, const UseItem('b', ShopItem.extraDie9)),
        throwsStateError,
      );
      expect(
        () => engine.apply(state, const UseItem('b', ShopItem.movementBoost)),
        throwsStateError,
      );
    });

    test('no se usa lo que no tiene, lo pasivo ni fuera de su turno', () {
      final engine = engineWith([]);
      final state = game(beto: beto(inventory: {ShopItem.shield: 1}));

      expect(engine.whyCannotUse(state, ShopItem.extraDie6), 'No tienes');
      expect(engine.whyCannotUse(state, ShopItem.shield), 'Se usa solo');
      expect(
        () => engine.apply(state, const UseItem('b', ShopItem.shield)),
        throwsStateError,
      );
      expect(
        () => engine.apply(state, const UseItem('a', ShopItem.shield)),
        throwsStateError,
      );
      expect(
        () => engine.apply(
          game(
            beto: beto(inventory: {ShopItem.extraDie6: 1}),
            phase: GamePhase.shopping,
          ),
          const UseItem('b', ShopItem.extraDie6),
        ),
        throwsStateError,
      );
    });
  });

  group('trampa', () {
    test('se pone en la casilla donde está el jugador', () {
      final engine = engineWith([]);
      final state = engine.apply(
        game(beto: beto(position: 4, inventory: {ShopItem.trap: 1})),
        const UseItem('b', ShopItem.trap),
      );

      expect(state.traps, {4: 'b'});
      expect(state.players['b']!.inventory, isEmpty);
      expect(state.players['b']!.itemsUsed, 1);
      expect(state.currentPlayerId, 'b');
    });

    test('no se pone en la salida, en una tienda ni sobre otra trampa', () {
      final engine = engineWith([]);
      const trap = {ShopItem.trap: 1};

      expect(
        engine.whyCannotUse(game(beto: beto(inventory: trap)), ShopItem.trap),
        'No se puede poner en esta casilla',
      );
      expect(
        engine.whyCannotUse(
          game(beto: beto(position: 12, inventory: trap)),
          ShopItem.trap,
        ),
        'No se puede poner en esta casilla',
      );
      expect(
        engine.whyCannotUse(
          game(
            beto: beto(position: 4, inventory: trap),
            traps: {4: 'a'},
          ),
          ShopItem.trap,
        ),
        'Ya hay una trampa aquí',
      );
    });

    test('al pasar por la trampa de otro le roban monedas', () {
      // Beto pasa por la 2 (trampa de Ana) y cae en la 4 (positiva, +3).
      final engine = engineWith([4]);
      final state = engine.apply(game(traps: {2: 'a'}), const RollDice('b'));

      expect(state.players['b']!.coins, 10 - 5 + 3);
      expect(state.players['a']!.coins, 10 + 5);
      expect(state.traps, isEmpty);
    });

    test('si tiene menos monedas, le roban las que tenga', () {
      final engine = engineWith([2]);
      final state = engine.apply(
        game(beto: beto(coins: 2), traps: {2: 'a'}),
        const RollDice('b'),
      );

      // Le roban 2 y luego gana 3 por la casilla positiva.
      expect(state.players['b']!.coins, 3);
      expect(state.players['a']!.coins, 12);
    });

    test('la trampa propia no hace nada y se queda', () {
      final engine = engineWith([4]);
      final state = engine.apply(game(traps: {2: 'b'}), const RollDice('b'));

      expect(state.players['b']!.coins, 13);
      expect(state.traps, {2: 'b'});
    });

    test('el escudo anula la trampa y los dos se gastan', () {
      final engine = engineWith([4]);
      final state = engine.apply(
        game(
          beto: beto(inventory: {ShopItem.shield: 1}),
          traps: {2: 'a'},
        ),
        const RollDice('b'),
      );

      expect(state.players['b']!.coins, 13);
      expect(state.players['b']!.inventory, isEmpty);
      expect(state.players['b']!.itemsUsed, 1);
      expect(state.players['a']!.coins, 10);
      expect(state.traps, isEmpty);
    });
  });

  group('ítems pasivos', () {
    test('el escudo anula la casilla negativa', () {
      final engine = engineWith([1]);
      final state = engine.apply(
        game(beto: beto(position: 6, inventory: {ShopItem.shield: 2})),
        const RollDice('b'),
      );

      final player = state.players['b']!;
      expect(player.position, 7);
      expect(player.coins, 10);
      expect(player.itemCount(ShopItem.shield), 1);
      // Para el premio de peor suerte sigue contando que cayó ahí.
      expect(player.negativeTiles, 1);
    });

    test('sin escudo la casilla negativa quita monedas', () {
      final engine = engineWith([1]);
      final state = engine.apply(
        game(beto: beto(position: 6)),
        const RollDice('b'),
      );

      expect(state.players['b']!.coins, 7);
    });

    test('el diamante doble da un diamante más y se gasta', () {
      // El diamante está en la 2; al tomarlo reaparece en la casilla 1.
      final engine = engineWith([2, 0]);
      final state = engine.apply(
        game(
          beto: beto(inventory: {ShopItem.diamondBoost: 1}),
          diamondTileId: 2,
        ),
        const RollDice('b'),
      );

      final player = state.players['b']!;
      expect(player.diamonds, 2);
      expect(player.mapDiamonds, 2);
      expect(player.inventory, isEmpty);
      expect(player.itemsUsed, 1);
      expect(state.diamondTileId, 1);
    });
  });

  group('mochila', () {
    test('suma y quita ítems sin dejar ceros guardados', () {
      const player = PlayerState(id: 'a', username: 'Ana');
      final more = player.addItem(ShopItem.trap, 2);
      expect(more.itemCount(ShopItem.trap), 2);

      final used = more.consumeItem(ShopItem.trap).consumeItem(ShopItem.trap);
      expect(used.inventory, isEmpty);
      expect(used.itemsUsed, 2);
    });

    test('los dados extra son de 3, 6 y 9 y los pasivos se usan solos', () {
      expect(
        [
          for (final item in ShopItem.values)
            if (item.isExtraDie) item.extraDieSides,
        ],
        [3, 6, 9],
      );
      expect(
        [
          for (final item in ShopItem.values)
            if (item.passive) item,
        ],
        [ShopItem.shield, ShopItem.diamondBoost],
      );
      for (final item in ShopItem.values) {
        expect(item.price, greaterThan(0));
      }
    });
  });
}
