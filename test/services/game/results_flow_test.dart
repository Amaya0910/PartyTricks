import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';
import 'package:party_tricks/services/game_engine/turn_order_resolver.dart';
import 'package:party_tricks/services/results/match_results_document.dart';
import 'package:party_tricks/services/stats/match_summary_builder.dart';
import 'package:party_tricks/services/stats/stats_calculator.dart';

import '../game_engine/fake_random_source.dart';
import '../game_engine/test_board.dart';

void main() {
  test('de la última acción a los resultados guardados, todo coincide', () {
    // Partida de 2 rondas jugada como en Firebase: cada acción pasa por el
    // codec y por hostApply.
    const codec = GameCodec();
    final engine = GameEngine(
      board: buildTestBoard(),
      // Diamante en la 41 y luego los dados: 2, 1, 2, 1 (todas positivas).
      random: FakeRandomSource([38, 2, 1, 2, 1]),
    );
    var stored = codec.encodeState(
      engine.start(
        initialRolls: const [
          InitialRoll(playerId: 'a', username: 'Ana', value: 6),
          InitialRoll(playerId: 'b', username: 'Beto', value: 1),
        ],
        totalRounds: 2,
      ),
    );
    for (final action in const [
      RollDice('a'),
      RollDice('b'),
      FinishMinigame(['a']),
      RollDice('a'),
      RollDice('b'),
      FinishMinigame(['b']),
    ]) {
      stored = hostApply(engine, stored, codec.encodeAction(action))!;
    }
    final game = codec.decodeState(stored);
    expect(game.phase, GamePhase.finished);

    // Lo que ve la pantalla.
    final results = const MatchResultsBuilder().build(game);
    final winner = results.ranking.first;
    // Puede terminar en empate: el primero siempre está entre los ganadores.
    expect(results.winnerIds, contains(winner.id));
    expect(winner.place, 1);
    expect(winner.experience, greaterThan(0));

    // Lo que guarda cada jugador en sus estadísticas y su cuenta.
    for (final result in results.ranking) {
      final summary = const MatchSummaryBuilder().build(
        matchId: 'sala-1',
        game: game,
        playerId: result.id,
      )!;
      expect(summary.place, result.place);
      expect(summary.experience, result.experience);
      expect(summary.diamonds, result.diamonds);
      expect(summary.coins, result.coins);
      expect(summary.won, results.winnerIds.contains(result.id));

      final stats = const StatsCalculator().applyMatch(
        PlayerStats.empty,
        summary,
      );
      expect(stats.matches.won, summary.won ? 1 : 0);
      expect(stats.matches.maxDiamonds, result.diamonds);
    }

    // Lo que guarda el anfitrión en el registro global.
    final record = MatchResultsDocument.fromMap(
      MatchResultsDocument.toMap(
        roomId: 'sala-1',
        hostUid: 'a',
        isPublic: false,
        results: results,
      ),
    );
    expect(record.winnerIds, results.winnerIds);
    expect(record.rounds, 2);
    expect(
      [for (final p in record.players) (p.uid, p.place, p.experience)],
      [for (final r in results.ranking) (r.id, r.place, r.experience)],
    );
  });
}
