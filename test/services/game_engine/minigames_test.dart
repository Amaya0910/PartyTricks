import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';

import 'fake_random_source.dart';

const _rules = MinigameRules();
const _players = ['ana', 'beto', 'caro'];

MinigameJudge _judge(List<int> randomValues) =>
    MinigameJudge(random: FakeRandomSource(randomValues));

/// Juega [moves] en orden y devuelve cómo terminó.
MinigameOutcome _playAll(
  MinigameJudge judge,
  MinigameState minigame,
  List<(String, int)> moves,
) {
  MinigameOutcome outcome = (state: minigame, result: null);
  for (final (id, score) in moves) {
    outcome = judge.play(outcome.state!, id, score);
  }
  return outcome;
}

void main() {
  group('Para el Tiempo', () {
    test('el objetivo sale al azar entre 4 y 19 segundos', () {
      final start = _judge([12]).start(MinigameType.stopwatch, 1, _players);
      expect(start.state!.targetMs, 12000);
      expect(start.result, isNull);
      expect(
        () => _judge([20]).start(MinigameType.stopwatch, 1, _players),
        throwsArgumentError,
        reason: 'el rango es de 4 a 19',
      );
    });

    test('gana la menor diferencia, por arriba o por abajo', () {
      final judge = _judge([10]);
      final minigame = judge.start(MinigameType.stopwatch, 1, _players).state!;
      final end = _playAll(judge, minigame, [
        ('ana', 10900),
        ('beto', 9800), // A 200 ms: la más cerca.
        ('caro', 12000),
      ]);
      expect(end.state, isNull);
      expect(end.result!.winnerIds, ['beto']);
      expect(end.result!.targetMs, 10000);
      expect(end.result!.scores, {'ana': 10900, 'beto': 9800, 'caro': 12000});
    });

    test('solo cuenta el primer toque', () {
      final judge = _judge([10]);
      final minigame = judge.start(MinigameType.stopwatch, 1, _players).state!;
      final after = judge.play(minigame, 'ana', 9000).state!;
      expect(() => judge.play(after, 'ana', 10000), throwsStateError);
    });

    test('un puntaje fuera de rango o de alguien que no juega no vale', () {
      final judge = _judge([10]);
      final minigame = judge.start(MinigameType.stopwatch, 1, _players).state!;
      expect(() => judge.play(minigame, 'ana', 25001), throwsStateError);
      expect(() => judge.play(minigame, 'ana', -5), throwsStateError);
      expect(() => judge.play(minigame, 'dani', 9000), throwsStateError);
    });

    test('empate: se lanza 1d6 hasta que uno saque más', () {
      // Objetivo 8 s; Ana y Caro quedan a 500 ms. Dados: 4-4 y luego 2-5.
      final judge = _judge([8, 4, 4, 2, 5]);
      final minigame = judge.start(MinigameType.stopwatch, 1, _players).state!;
      final end = _playAll(judge, minigame, [
        ('ana', 7500),
        ('beto', 9000),
        ('caro', 8500),
      ]);
      expect(end.result!.winnerIds, ['caro']);
      expect(end.result!.tiebreak, {
        'ana': [4, 2],
        'caro': [4, 5],
      });
    });

    test('al acabarse el tiempo, los que no tocaron no valen', () {
      final judge = _judge([10]);
      final minigame = judge.start(MinigameType.stopwatch, 1, _players).state!;
      final after = judge.play(minigame, 'beto', 14000).state!;
      final end = judge.timeout(after, after.step);
      expect(end.result!.winnerIds, ['beto']);
      expect(end.result!.scores, {
        'ana': MinigameRules.noScore,
        'beto': 14000,
        'caro': MinigameRules.noScore,
      });
    });

    test('un cierre por tiempo de un paso viejo se ignora', () {
      final judge = _judge([10]);
      final minigame = judge.start(MinigameType.stopwatch, 1, _players).state!;
      final after = judge.play(minigame, 'beto', 14000).state!;
      expect(() => judge.timeout(after, 0), throwsStateError);
    });

    test('si nadie tocó a tiempo, nadie gana', () {
      final judge = _judge([10]);
      final minigame = judge.start(MinigameType.stopwatch, 1, _players).state!;
      final end = judge.timeout(minigame, 0);
      expect(end.result!.winnerIds, isEmpty);
    });
  });

  group('Reacción', () {
    test('la espera sale al azar entre 2 y 7 segundos', () {
      final start = _judge([4321]).start(MinigameType.reaction, 2, _players);
      expect(start.state!.delayMs, 4321);
      expect(start.state!.round, 2);
    });

    test('gana el más rápido; el que se adelantó queda fuera', () {
      final judge = _judge([3000]);
      final minigame = judge.start(MinigameType.reaction, 1, _players).state!;
      final end = _playAll(judge, minigame, [
        ('ana', MinigameRules.noScore), // Tocó antes del "¡YA!".
        ('beto', 410),
        ('caro', 350),
      ]);
      expect(end.result!.winnerIds, ['caro']);
    });

    test('empate en ms: se desempata con 1d6', () {
      final judge = _judge([3000, 6, 3]);
      final minigame = judge.start(MinigameType.reaction, 1, _players).state!;
      final end = _playAll(judge, minigame, [
        ('ana', 300),
        ('beto', 300),
        ('caro', 450),
      ]);
      expect(end.result!.winnerIds, ['ana']);
      expect(end.result!.tiebreak, {
        'ana': [6],
        'beto': [3],
      });
    });

    test('al acabarse el tiempo se decide con los que tocaron', () {
      final judge = _judge([3000]);
      final minigame = judge.start(MinigameType.reaction, 1, _players).state!;
      final after = judge.play(minigame, 'ana', 520).state!;
      final end = judge.timeout(after, after.step);
      expect(end.result!.winnerIds, ['ana']);
    });

    test('si todos se adelantan, nadie gana', () {
      final judge = _judge([3000]);
      final minigame = judge.start(MinigameType.reaction, 1, _players).state!;
      final end = _playAll(judge, minigame, [
        for (final id in _players) (id, MinigameRules.noScore),
      ]);
      expect(end.result!.winnerIds, isEmpty);
    });

    test('el tiempo para cerrar incluye la explicación y la espera', () {
      final minigame = _judge([
        3000,
      ]).start(MinigameType.reaction, 1, _players).state!;
      expect(
        _rules.timeLimit(minigame),
        Duration(
          milliseconds:
              _rules.introMs + 3000 + _rules.reactionLimitMs + _rules.graceMs,
        ),
      );
    });
  });

  group('Globo Bomba', () {
    test('la capacidad sale al azar y empieza uno distinto cada ronda', () {
      final round1 = _judge([40]).start(MinigameType.balloon, 1, _players);
      expect(round1.state!.capacity, 40);
      expect(round1.state!.balloonPlayer, 'ana');
      final round2 = _judge([40]).start(MinigameType.balloon, 2, _players);
      expect(round2.state!.balloonPlayer, 'beto');
      expect(
        () => _judge([71]).start(MinigameType.balloon, 1, _players),
        throwsArgumentError,
      );
    });

    test('por turnos, inflando de 1 a 3', () {
      final judge = _judge([30]);
      final minigame = judge.start(MinigameType.balloon, 1, _players).state!;
      expect(() => judge.play(minigame, 'beto', 1), throwsStateError);
      expect(() => judge.play(minigame, 'ana', 0), throwsStateError);
      expect(() => judge.play(minigame, 'ana', 4), throwsStateError);
      final after = judge.play(minigame, 'ana', 3).state!;
      expect(after.pumps, 3);
      expect(after.balloonPlayer, 'beto');
      expect(after.step, 1);
    });

    test('al que se le revienta sale y sigue otro globo; gana el último', () {
      // Primer globo aguanta 30, el segundo 35.
      final judge = _judge([30, 35]);
      var minigame = judge.start(MinigameType.balloon, 1, _players).state!;
      minigame = minigame.copyWith(pumps: 28); // Ya va casi lleno.
      final popped = judge.play(minigame, 'ana', 2).state!;
      expect(popped.out, ['ana']);
      expect(popped.pumps, 0);
      expect(popped.capacity, 35);
      expect(popped.balloonPlayer, 'beto');

      final last = judge.play(popped.copyWith(pumps: 34), 'beto', 3);
      expect(last.state, isNull);
      expect(last.result!.winnerIds, ['caro']);
      expect(last.result!.out, ['ana', 'beto']);
    });

    test('los que ya salieron no vuelven a inflar', () {
      final judge = _judge([30, 50]);
      var minigame = judge
          .start(MinigameType.balloon, 1, _players)
          .state!
          .copyWith(pumps: 29);
      minigame = judge.play(minigame, 'ana', 1).state!; // Ana sale.
      minigame = judge.play(minigame, 'beto', 1).state!;
      minigame = judge.play(minigame, 'caro', 1).state!;
      expect(minigame.balloonPlayer, 'beto', reason: 'se salta a Ana');
    });

    test('si no infla a tiempo, se infla 1 por él', () {
      final judge = _judge([30]);
      final minigame = judge.start(MinigameType.balloon, 1, _players).state!;
      final after = judge.timeout(minigame, 0).state!;
      expect(after.pumps, 1);
      expect(after.balloonPlayer, 'beto');
    });

    test('con un solo jugador, gana sin jugar', () {
      final start = _judge([30]).start(MinigameType.balloon, 1, ['ana']);
      expect(start.state, isNull);
      expect(start.result!.winnerIds, ['ana']);
    });
  });

  test('los ids de los minijuegos se leen de vuelta', () {
    for (final type in MinigameType.values) {
      expect(MinigameType.byId(type.name), type);
    }
    expect(MinigameType.byId('nuevo'), isNull);
  });
}
