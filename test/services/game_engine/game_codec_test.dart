import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'package:party_tricks/services/game_engine/tile_effects.dart';

void main() {
  const codec = GameCodec();

  test('el estado se guarda y se lee igual', () {
    const state = GameState(
      players: {
        'a': PlayerState(
          id: 'a',
          username: 'Ana',
          position: 30,
          coins: 7,
          diamonds: 1,
          pendingEffect: PendingEffect.die12,
          minigamesWon: 2,
          negativeTiles: 3,
          purchases: 1,
          diceRolled: 4,
          diceTotal: 15,
          maxRolls: 1,
          positiveTiles: 2,
          specialTiles: 1,
          mainPathsTaken: 3,
          shortcutsTaken: 2,
          laps: 1,
          mapDiamonds: 1,
        ),
        'b': PlayerState(id: 'b', username: 'Beto'),
      },
      turnOrder: ['b', 'a'],
      totalRounds: 10,
      round: 4,
      turnIndex: 1,
      phase: GamePhase.choosingBranch,
      diamondTileId: 17,
      stepsLeft: 2,
      lastRoll: 5,
    );

    final read = codec.decodeState(codec.encodeState(state));

    expect(read.turnOrder, ['b', 'a']);
    expect(read.round, 4);
    expect(read.currentPlayerId, 'a');
    expect(read.phase, GamePhase.choosingBranch);
    expect(read.diamondTileId, 17);
    expect(read.stepsLeft, 2);
    expect(read.lastRoll, 5);
    final ana = read.players['a']!;
    expect(ana.position, 30);
    expect(ana.coins, 7);
    expect(ana.pendingEffect, PendingEffect.die12);
    expect(ana.minigamesWon, 2);
    expect(ana.negativeTiles, 3);
    expect(ana.diceRolled, 4);
    expect(ana.diceTotal, 15);
    expect(ana.maxRolls, 1);
    expect(ana.positiveTiles, 2);
    expect(ana.specialTiles, 1);
    expect(ana.mainPathsTaken, 3);
    expect(ana.shortcutsTaken, 2);
    expect(ana.laps, 1);
    expect(ana.mapDiamonds, 1);
    expect(read.players['b']!.pendingEffect, isNull);
  });

  test('lee números que la base de datos devuelve como double', () {
    final read = codec.decodeState({
      'players': {
        'a': {'username': 'Ana', 'position': 3.0, 'coins': 10.0},
      },
      'turnOrder': ['a'],
      'totalRounds': 5.0,
      'round': 1,
      'turnIndex': 0,
      'phase': 'rolling',
      'diamondTileId': 41,
    });

    expect(read.players['a']!.position, 3);
    expect(read.players['a']!.diamonds, 0);
    // Las partidas guardadas antes de los contadores los leen en 0.
    expect(read.players['a']!.diceRolled, 0);
    expect(read.players['a']!.laps, 0);
    expect(read.totalRounds, 5);
  });

  test('las acciones se guardan y se leen igual', () {
    final roll = codec.decodeAction(codec.encodeAction(const RollDice('a')));
    expect((roll as RollDice).playerId, 'a');

    final branch = codec.decodeAction(
      codec.encodeAction(const ChooseBranch('a', 1)),
    );
    expect((branch as ChooseBranch).branch, 1);

    final minigame = codec.decodeAction(
      codec.encodeAction(const FinishMinigame(['a', 'b'])),
    );
    expect((minigame as FinishMinigame).winnerIds, ['a', 'b']);
  });

  test('rechaza acciones desconocidas', () {
    expect(() => codec.decodeAction({'type': 'trampa'}), throwsFormatException);
    expect(
      () => codec.decodeAction({'type': 'buy', 'playerId': 'a', 'item': 'x'}),
      throwsFormatException,
    );
  });

  group('tiendas e ítems', () {
    test('la mochila, los ítems activos y las trampas se guardan', () {
      const state = GameState(
        players: {
          'a': PlayerState(
            id: 'a',
            username: 'Ana',
            inventory: {ShopItem.shield: 2, ShopItem.trap: 1},
            activeItems: [ShopItem.extraDie9, ShopItem.movementBoost],
            itemsUsed: 4,
          ),
        },
        turnOrder: ['a'],
        totalRounds: 5,
        phase: GamePhase.shopping,
        diamondTileId: 3,
        lastRoll: 2,
        lastExtraRoll: 7,
        lastBoost: 3,
        traps: {17: 'a', 4: 'b'},
      );

      final encoded = codec.encodeState(state);
      // Claves de texto para que la base de datos no lo vuelva lista.
      expect((encoded['traps'] as Map).keys, containsAll(['t17', 't4']));

      final read = codec.decodeState(encoded);
      expect(read.phase, GamePhase.shopping);
      expect(read.lastExtraRoll, 7);
      expect(read.lastBoost, 3);
      expect(read.traps, {17: 'a', 4: 'b'});
      final ana = read.players['a']!;
      expect(ana.inventory, {ShopItem.shield: 2, ShopItem.trap: 1});
      expect(ana.activeItems, [ShopItem.extraDie9, ShopItem.movementBoost]);
      expect(ana.itemsUsed, 4);
    });

    test('una partida guardada antes de las tiendas se lee sin ítems', () {
      final read = codec.decodeState({
        'players': {
          'a': {'username': 'Ana', 'position': 3, 'coins': 10},
        },
        'turnOrder': ['a'],
        'totalRounds': 5,
        'round': 1,
        'turnIndex': 0,
        'phase': 'rolling',
        'diamondTileId': 41,
      });

      expect(read.traps, isEmpty);
      expect(read.lastExtraRoll, 0);
      expect(read.players['a']!.inventory, isEmpty);
      expect(read.players['a']!.activeItems, isEmpty);
      expect(read.players['a']!.itemsUsed, 0);
    });

    test('lee lo que la base de datos devuelve con otros tipos', () {
      final read = codec.decodeState({
        'players': {
          'a': {
            'username': 'Ana',
            'inventory': {'shield': 1.0, 'trap': 0, 'cohete': 2},
            // Una lista con huecos vuelve como mapa.
            'activeItems': {'1': 'movementBoost'},
          },
        },
        'turnOrder': ['a'],
        'totalRounds': 5,
        'phase': 'rolling',
        'diamondTileId': 41,
      });

      final ana = read.players['a']!;
      // Los ítems en 0 y los que esta versión no conoce no se cargan.
      expect(ana.inventory, {ShopItem.shield: 1});
      expect(ana.activeItems, [ShopItem.movementBoost]);
    });

    test('las acciones de la tienda se guardan y se leen igual', () {
      final buy = codec.decodeAction(
        codec.encodeAction(const BuyItem('a', ShopItem.diamondBoost)),
      );
      expect((buy as BuyItem).playerId, 'a');
      expect(buy.item, ShopItem.diamondBoost);

      final use = codec.decodeAction(
        codec.encodeAction(const UseItem('a', ShopItem.trap)),
      );
      expect((use as UseItem).item, ShopItem.trap);

      final leave = codec.decodeAction(
        codec.encodeAction(const LeaveShop('a')),
      );
      expect((leave as LeaveShop).playerId, 'a');
    });
  });
}
