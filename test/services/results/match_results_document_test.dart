import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';
import 'package:party_tricks/services/results/match_results_document.dart';

void main() {
  final results = const MatchResultsBuilder().build(
    const GameState(
      players: {
        'b': PlayerState(id: 'b', username: 'Beto', diamonds: 1, coins: 4),
        'a': PlayerState(
          id: 'a',
          username: 'Ana',
          diamonds: 3,
          coins: 12,
          purchases: 2,
        ),
      },
      turnOrder: ['b', 'a'],
      totalRounds: 5,
      round: 5,
      diamondTileId: 1,
      phase: GamePhase.finished,
    ),
  );

  Map<String, dynamic> encoded() => MatchResultsDocument.toMap(
    roomId: 'sala-1',
    hostUid: 'b',
    isPublic: true,
    results: results,
  );

  test('guarda lo que necesitan las reglas y los rankings', () {
    final map = encoded();

    expect(map['schemaVersion'], MatchResultsDocument.schemaVersion);
    expect(map['roomId'], 'sala-1');
    expect(map['hostUid'], 'b');
    expect(map['playerIds'], ['a', 'b']);
    expect(map['winnerIds'], ['a']);
    expect(map['rounds'], 5);
    final first = (map['players'] as List).first as Map;
    expect(first['uid'], 'a');
    expect(first['place'], 1);
    expect(first['diamonds'], 5); // 3 + más monedas + más comprador.
    expect(first['experience'], results.of('a')!.experience);
    expect(first['awards'], ['richest', 'topBuyer']);
  });

  test('se lee de vuelta igual', () {
    final record = MatchResultsDocument.fromMap(encoded());

    expect(record.roomId, 'sala-1');
    expect(record.hostUid, 'b');
    expect(record.isPublic, isTrue);
    expect(record.rounds, 5);
    expect(record.winnerIds, ['a']);
    expect([for (final p in record.players) p.uid], ['a', 'b']);
    final ana = record.players.first;
    expect(ana.username, 'Ana');
    expect(ana.coins, 12);
    expect(ana.diamonds, 5);
    expect(ana.experience, results.of('a')!.experience);
    expect(ana.awards, [FinalAward.richest, FinalAward.topBuyer]);
  });

  test('lee registros incompletos o con datos que no conoce', () {
    final record = MatchResultsDocument.fromMap({
      'roomId': 'sala-2',
      'rounds': 7.0,
      'players': [
        {
          'uid': 'a',
          'username': 'Ana',
          'place': 1,
          'awards': ['richest', 'premioNuevo'],
        },
        'basura',
      ],
    });

    expect(record.rounds, 7);
    expect(record.isPublic, isFalse);
    expect(record.winnerIds, isEmpty);
    expect(record.players, hasLength(1));
    expect(record.players.single.awards, [FinalAward.richest]);
    expect(record.players.single.experience, 0);
  });
}
