import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/match_summary.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'package:party_tricks/services/stats/firestore_stats_document.dart';
import 'package:party_tricks/services/stats/match_summary_builder.dart';

import 'fake_random_source.dart';
import 'test_board.dart';

GameEngine engineWith(List<int> randomValues) =>
    GameEngine(board: buildTestBoard(), random: FakeRandomSource(randomValues));

/// Beto juega primero. El diamante está lejos.
GameState game({
  GamePhase phase = GamePhase.rolling,
  PlayerState beto = const PlayerState(id: 'b', username: 'Beto', coins: 10),
  int stepsLeft = 0,
}) {
  return GameState(
    players: {
      'b': beto,
      'a': const PlayerState(id: 'a', username: 'Ana', coins: 10),
    },
    turnOrder: const ['b', 'a'],
    totalRounds: 5,
    diamondTileId: 41,
    phase: phase,
    stepsLeft: stepsLeft,
  );
}

void main() {
  group('saltar el turno de un desconectado', () {
    test('al lanzar: pierde la tirada y pasa el turno', () {
      final state = engineWith([]).apply(game(), const SkipTurn('b'));

      final beto = state.players['b']!;
      expect(beto.position, 0);
      expect(beto.diceRolled, 0);
      expect(beto.away, isTrue);
      expect(beto.missedTurns, 1);
      expect(state.currentPlayerId, 'a');
      expect(state.phase, GamePhase.rolling);
    });

    test('en la tienda: sale sin comprar y no se queda bloqueada', () {
      final state = engineWith([]).apply(
        game(
          phase: GamePhase.shopping,
          beto: const PlayerState(
            id: 'b',
            username: 'Beto',
            position: 12,
            coins: 10,
          ),
        ),
        const SkipTurn('b'),
      );

      expect(state.phase, GamePhase.rolling);
      expect(state.currentPlayerId, 'a');
      expect(state.players['b']!.coins, 10);
      expect(state.players['b']!.purchases, 0);
    });

    test('en una bifurcación: sigue por el camino principal', () {
      final state = engineWith([]).apply(
        game(
          phase: GamePhase.choosingBranch,
          beto: const PlayerState(id: 'b', username: 'Beto', position: 5),
          stepsLeft: 1,
        ),
        const SkipTurn('b'),
      );

      expect(state.players['b']!.position, 6);
      expect(state.players['b']!.mainPathsTaken, 1);
      expect(state.currentPlayerId, 'a');
    });

    test('solo en el turno de ese jugador y fuera del minijuego', () {
      final engine = engineWith([]);
      expect(() => engine.apply(game(), const SkipTurn('a')), throwsStateError);
      expect(
        () =>
            engine.apply(game(phase: GamePhase.minigame), const SkipTurn('b')),
        throwsStateError,
      );
      expect(
        () =>
            engine.apply(game(phase: GamePhase.finished), const SkipTurn('b')),
        throwsStateError,
      );
    });
  });

  group('al volver', () {
    test('recupera su estado: monedas, ítems y posición siguen ahí', () {
      final engine = engineWith([2]);
      final away = game(
        beto: const PlayerState(
          id: 'b',
          username: 'Beto',
          position: 3,
          coins: 7,
          away: true,
          missedTurns: 2,
          inventory: {ShopItem.shield: 1},
        ),
      );

      final state = engine.apply(away, const RollDice('b'));

      final beto = state.players['b']!;
      expect(beto.away, isFalse);
      expect(beto.position, 5);
      expect(beto.itemCount(ShopItem.shield), 1);
      expect(beto.missedTurns, 2);
    });

    test('una acción que no vale no lo marca como de vuelta', () {
      final engine = engineWith([]);
      final away = game(
        beto: const PlayerState(id: 'b', username: 'Beto', away: true),
      );
      expect(() => engine.apply(away, const LeaveShop('b')), throwsStateError);
      expect(away.players['b']!.away, isTrue);
    });
  });

  group('resultados de quien termina desconectado', () {
    final finished = GameState(
      players: const {
        'b': PlayerState(id: 'b', username: 'Beto', diamonds: 5, coins: 9),
        'a': PlayerState(
          id: 'a',
          username: 'Ana',
          diamonds: 1,
          coins: 4,
          away: true,
        ),
      },
      turnOrder: const ['b', 'a'],
      totalRounds: 5,
      round: 5,
      diamondTileId: 41,
      phase: GamePhase.finished,
    );

    test('no gana XP aunque quede en el podio', () {
      final results = const MatchResultsBuilder().build(finished);
      expect(results.of('a')!.place, 2);
      expect(results.of('a')!.disconnected, isTrue);
      expect(results.of('a')!.experience, 0);
      expect(results.of('b')!.experience, greaterThan(0));
    });

    test('no se lleva monedas ni diamantes a la cuenta', () {
      final summary = const MatchSummaryBuilder().build(
        matchId: 'sala',
        game: finished,
        playerId: 'a',
      )!;
      expect(summary.disconnected, isTrue);
      expect(FirestoreStatsDocument.matchRewardAmounts(summary), {
        'experience': 0,
        'coins': 0,
        'diamonds': 0,
      });
      // Las estadísticas sí cuentan la partida tal como fue.
      expect(summary.coins, 4);
    });

    test('quien termina conectado se lleva lo suyo', () {
      const summary = MatchSummary(
        matchId: 'sala',
        won: true,
        place: 1,
        diamonds: 5,
        coins: 9,
        experience: 60,
        minigamesWon: 0,
        minigamesPlayed: 5,
      );
      expect(FirestoreStatsDocument.matchRewardAmounts(summary), {
        'experience': 60,
        'coins': 9,
        'diamonds': 5,
      });
    });
  });

  test('el codec guarda la ausencia y la acción de saltar', () {
    const codec = GameCodec();
    final read = codec.decodeState(
      codec.encodeState(
        game(
          beto: const PlayerState(
            id: 'b',
            username: 'Beto',
            away: true,
            missedTurns: 3,
          ),
        ),
      ),
    );
    expect(read.players['b']!.away, isTrue);
    expect(read.players['b']!.missedTurns, 3);
    expect(read.players['a']!.away, isFalse);

    final skip = codec.decodeAction(codec.encodeAction(const SkipTurn('b')));
    expect((skip as SkipTurn).playerId, 'b');
  });
}
