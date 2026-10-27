import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
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
  });
}
