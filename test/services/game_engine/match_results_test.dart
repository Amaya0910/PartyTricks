import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/experience_calculator.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';

GameState finished(List<PlayerState> players, {int rounds = 10}) {
  return GameState(
    players: {for (final p in players) p.id: p},
    turnOrder: [for (final p in players) p.id],
    totalRounds: rounds,
    round: rounds,
    diamondTileId: 1,
    phase: GamePhase.finished,
  );
}

void main() {
  const builder = MatchResultsBuilder();

  test('ordena del primero al último con los diamantes finales sumados', () {
    final results = builder.build(
      finished(const [
        PlayerState(id: 'c', username: 'Caro', diamonds: 1),
        PlayerState(id: 'a', username: 'Ana', diamonds: 3, coins: 20),
        PlayerState(id: 'b', username: 'Beto', diamonds: 2, negativeTiles: 4),
      ]),
    );

    expect([for (final r in results.ranking) r.id], ['a', 'b', 'c']);
    expect([for (final r in results.ranking) r.place], [1, 2, 3]);
    // Ana: 3 + más monedas. Beto: 2 + peor suerte.
    expect(results.of('a')!.diamonds, 4);
    expect(results.of('a')!.awards, [FinalAward.richest]);
    expect(results.of('b')!.diamonds, 3);
    expect(results.of('b')!.awards, [FinalAward.worstLuck]);
    expect(results.winnerIds, ['a']);
    expect(results.isTie, isFalse);
    expect(results.rounds, 10);
    expect(results.of('z'), isNull);
  });

  test('la XP es la del ExperienceCalculator para cada puesto', () {
    const xp = ExperienceCalculator();
    final results = builder.build(
      finished(const [
        PlayerState(id: 'a', username: 'Ana', diamonds: 5),
        PlayerState(id: 'b', username: 'Beto', diamonds: 3),
        PlayerState(id: 'c', username: 'Caro', diamonds: 2),
        PlayerState(id: 'd', username: 'Dani', diamonds: 1),
      ], rounds: 15),
    );

    for (final r in results.ranking) {
      expect(
        r.experience,
        xp.xpForMatch(place: r.place, players: 4, rounds: 15),
      );
    }
    // Del 4.º puesto en adelante no se gana XP.
    expect(results.of('d')!.experience, 0);
    expect(results.of('a')!.experience, greaterThan(0));
  });

  test('en un empate comparten puesto y ganan los dos', () {
    final results = builder.build(
      finished(const [
        PlayerState(id: 'b', username: 'Beto', diamonds: 2, coins: 5),
        PlayerState(id: 'a', username: 'Ana', diamonds: 2, coins: 5),
        PlayerState(id: 'c', username: 'Caro'),
      ]),
    );

    expect(results.isTie, isTrue);
    expect(results.winnerIds, unorderedEquals(['a', 'b']));
    // Mismo puesto y mismas monedas: van por nombre.
    expect([for (final r in results.ranking) r.id], ['a', 'b', 'c']);
    expect(results.of('a')!.place, 1);
    expect(results.of('b')!.place, 1);
    expect(results.of('c')!.place, 3);
    expect(results.of('a')!.experience, results.of('b')!.experience);
  });

  test('cada diamante final tiene su nombre', () {
    expect(
      [for (final award in FinalAward.values) award.label],
      ['Más minijuegos ganados', 'Peor suerte', 'Más monedas', 'Más comprador'],
    );
  });
}
