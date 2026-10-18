import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';

GameState finishedGame(List<PlayerState> players) {
  return GameState(
    players: {for (final p in players) p.id: p},
    turnOrder: [for (final p in players) p.id],
    totalRounds: 5,
    diamondTileId: 1,
    phase: GamePhase.finished,
  );
}

void main() {
  const calculator = AwardCalculator();

  test('entrega cada diamante final al que más tiene', () {
    final result = calculator.calculate(
      finishedGame(const [
        PlayerState(id: 'a', username: 'Ana', minigamesWon: 3, coins: 5),
        PlayerState(id: 'b', username: 'Beto', negativeTiles: 4, coins: 20),
        PlayerState(id: 'c', username: 'Caro', purchases: 2, coins: 1),
      ]),
    );

    expect(result.awards[FinalAward.minigames], ['a']);
    expect(result.awards[FinalAward.worstLuck], ['b']);
    expect(result.awards[FinalAward.richest], ['b']);
    expect(result.awards[FinalAward.topBuyer], ['c']);
  });

  test('si hay empate en una categoría, todos reciben el diamante', () {
    final result = calculator.calculate(
      finishedGame(const [
        PlayerState(id: 'a', username: 'Ana', coins: 10),
        PlayerState(id: 'b', username: 'Beto', coins: 10),
      ]),
    );

    expect(result.awards[FinalAward.richest], ['a', 'b']);
  });

  test('si nadie tiene nada en una categoría, nadie la gana', () {
    final result = calculator.calculate(
      finishedGame(const [
        PlayerState(id: 'a', username: 'Ana', coins: 10),
        PlayerState(id: 'b', username: 'Beto', coins: 3),
      ]),
    );

    expect(result.awards[FinalAward.topBuyer], isEmpty);
  });

  test('gana el que tiene más diamantes, sumando los finales', () {
    final result = calculator.calculate(
      finishedGame(const [
        PlayerState(id: 'a', username: 'Ana', diamonds: 2),
        PlayerState(id: 'b', username: 'Beto', diamonds: 1, coins: 30),
        PlayerState(id: 'c', username: 'Caro', minigamesWon: 1),
      ]),
    );

    expect(result.diamonds, {'a': 2, 'b': 2, 'c': 1});
    expect(result.winnerIds, ['a', 'b']);
    expect(result.places, {'a': 1, 'b': 1, 'c': 3});
  });
}
