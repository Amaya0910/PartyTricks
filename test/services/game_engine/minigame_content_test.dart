import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';

const _rules = MinigameRules();

/// Evalúa una cuenta como "7 + 8" o "6 × 3".
int _solve(String text) {
  final [left, sign, right] = text.split(' ');
  final a = int.parse(left);
  final b = int.parse(right);
  return switch (sign) {
    '+' => a + b,
    '-' => a - b,
    _ => a * b,
  };
}

void main() {
  group('la secuencia con semilla', () {
    test('la misma semilla da siempre los mismos números', () {
      // Estos valores no pueden cambiar: si cambian, dos versiones de la app
      // jugarían tableros distintos en la misma partida.
      final sequence = MinigameSequence(12345);
      expect(
        [for (var i = 0; i < 6; i++) sequence.next(0, 999)],
        [766, 21, 228, 873, 536, 691],
      );
    });

    test('semillas distintas dan contenido distinto', () {
      expect(diceMemoryFaces(1, 15), isNot(diceMemoryFaces(2, 15)));
    });

    test('nunca se sale del rango', () {
      final sequence = MinigameSequence(99);
      for (var i = 0; i < 2000; i++) {
        expect(sequence.next(3, 7), inInclusiveRange(3, 7));
      }
    });

    test('revolver no pierde ni repite nada', () {
      final items = [1, 2, 3, 4, 5, 6];
      final shuffled = MinigameSequence(5).shuffled(items);
      expect(shuffled, unorderedEquals(items));
      expect(items, [1, 2, 3, 4, 5, 6], reason: 'no toca la lista original');
    });
  });

  group('Pulso Perfecto', () {
    test('el ritmo es igual para todos y queda en el rango', () {
      final beat = rhythmBeatMs(77, min: 420, max: 720);
      expect(beat, rhythmBeatMs(77, min: 420, max: 720));
      expect(beat, inInclusiveRange(420, 720));
    });

    test('un mal comienzo solo cuenta en el primer toque', () {
      final errors = rhythmErrors(
        [2150, 2650, 3150],
        beatMs: 500,
        firstBeatMs: 2000,
      );
      expect(errors, [150, 0, 0]);
      expect(rhythmAverage(errors), 50);
    });

    test('sin toques no hay desvío', () {
      expect(rhythmAverage(const []), 0);
    });
  });

  group('Memoria de Dados', () {
    test('salen caras válidas, sin dos iguales seguidas', () {
      for (var seed = 1; seed < 50; seed++) {
        final faces = diceMemoryFaces(seed, 15);
        expect(faces, hasLength(15));
        expect(faces.every((face) => face >= 1 && face <= 6), isTrue);
        for (var i = 1; i < faces.length; i++) {
          expect(faces[i], isNot(faces[i - 1]));
        }
      }
    });
  });

  group('Cazamonedas', () {
    test('el guion es igual para todos', () {
      final one = coinRainScript(8, _rules.coinRainMs);
      final two = coinRainScript(8, _rules.coinRainMs);
      expect(one.map((item) => item.startMs), two.map((item) => item.startMs));
      expect(one.map((item) => item.x), two.map((item) => item.x));
    });

    test('caen de todo y a tiempo', () {
      for (var seed = 1; seed < 40; seed++) {
        final items = coinRainScript(seed, _rules.coinRainMs);
        expect(items.length, greaterThan(30));
        expect(
          items.where((item) => item.kind == FallingKind.coin).length,
          greaterThan(items.length ~/ 3),
          reason: 'la mayoría de lo que cae debe servir',
        );
        for (final item in items) {
          expect(item.startMs, lessThan(_rules.coinRainMs));
          expect(item.x, inInclusiveRange(0.0, 1.0));
          expect(item.fallMs, greaterThan(0));
        }
      }
    });

    test('nunca da más puntos de los que se aceptan', () {
      for (var seed = 1; seed < 40; seed++) {
        final best = coinRainScript(seed, _rules.coinRainMs)
            .map((item) => item.kind.points)
            .where((points) => points > 0)
            .fold(0, (sum, points) => sum + points);
        expect(best, lessThanOrEqualTo(_rules.coinRainMaxScore));
      }
    });
  });

  group('Color Tramposo', () {
    List<ColorTrapRound> script(int seed) => colorTrapScript(
      seed,
      rounds: _rules.colorTrapRounds,
      flipFrom: _rules.colorTrapFlipFrom,
      colors: _rules.colorTrapColors,
    );

    test('la palabra nunca coincide con la tinta', () {
      for (var seed = 1; seed < 40; seed++) {
        for (final round in script(seed)) {
          expect(round.word, isNot(round.ink));
        }
      }
    });

    test('hay cuatro botones distintos con la tinta y la palabra', () {
      for (var seed = 1; seed < 40; seed++) {
        for (final round in script(seed)) {
          expect(round.choices.toSet(), hasLength(4));
          expect(round.choices, contains(round.ink));
          expect(round.choices, contains(round.word));
        }
      }
    });

    test('la regla se voltea a partir de la vuelta indicada', () {
      final rounds = script(3);
      expect(
        rounds.take(_rules.colorTrapFlipFrom).every((r) => !r.flipped),
        isTrue,
      );
      expect(
        rounds.skip(_rules.colorTrapFlipFrom).every((r) => r.flipped),
        isTrue,
      );
      expect(rounds.first.answer, rounds.first.ink);
      expect(rounds.last.answer, rounds.last.word);
    });

    test('más rápido y con racha vale más, sin pasarse del máximo', () {
      final limit = _rules.colorTrapWordMs;
      final slow = colorTrapPoints(spentMs: limit, limitMs: limit, streak: 1);
      final fast = colorTrapPoints(spentMs: 0, limitMs: limit, streak: 1);
      final best = colorTrapPoints(spentMs: 0, limitMs: limit, streak: 99);
      expect(slow, 60);
      expect(fast, 110);
      expect(best, 150);
      expect(
        best * _rules.colorTrapRounds,
        lessThanOrEqualTo(_rules.colorTrapMaxScore),
      );
    });
  });

  group('Cuenta Rápida', () {
    test('una de las dos respuestas es la correcta y la otra no', () {
      for (var seed = 1; seed < 40; seed++) {
        for (final problem in quickMathScript(seed, 70)) {
          final answer = _solve(problem.text);
          final right = problem.leftIsRight ? problem.left : problem.right;
          final wrong = problem.leftIsRight ? problem.right : problem.left;
          expect(right, answer);
          expect(wrong, isNot(answer));
          expect(wrong, greaterThan(0));
        }
      }
    });

    test('empieza fácil y se va complicando', () {
      final problems = quickMathScript(11, 30);
      expect(problems.first.text, contains('+'));
      expect(_solve(problems.first.text), lessThanOrEqualTo(18));
      expect(problems[15].text, contains('×'));
    });

    test('la racha da más puntos, con un tope', () {
      expect(quickMathPoints(1), 10);
      expect(quickMathPoints(2), 12);
      expect(quickMathPoints(11), 30);
      expect(quickMathPoints(50), 30);
    });
  });

  group('Cofre Fuerte', () {
    test('cada cerrojo es más difícil que el anterior', () {
      final locks = safeLockScript(4, _rules.safeLocks);
      for (var i = 1; i < locks.length; i++) {
        expect(locks[i].widthDeg, lessThan(locks[i - 1].widthDeg));
        expect(
          locks[i].turnsPerSecond.abs(),
          greaterThan(locks[i - 1].turnsPerSecond.abs()),
        );
      }
    });

    test('la aguja nunca empieza dentro de la marca', () {
      for (var seed = 1; seed < 100; seed++) {
        for (final lock in safeLockScript(seed, _rules.safeLocks)) {
          expect(
            safeLockDistance(lock.needleAt(0), lock.markDeg),
            greaterThan(lock.widthDeg / 2),
          );
        }
      }
    });

    test('la aguja gira y vuelve a pasar por el mismo lugar', () {
      const lock = SafeLockSetup(
        markDeg: 0,
        widthDeg: 40,
        startDeg: 90,
        turnsPerSecond: 0.5,
      );
      expect(lock.needleAt(0), 90);
      expect(lock.needleAt(500), 180);
      expect(lock.needleAt(2000), 90);
    });

    test('la distancia da la vuelta por el camino corto', () {
      expect(safeLockDistance(350, 10), 20);
      expect(safeLockDistance(10, 350), 20);
      expect(safeLockDistance(180, 0), 180);
    });

    test('al centro vale más; afuera, nada', () {
      expect(safeLockPoints(0, 40), 150, reason: 'perfecto: 100 + 50');
      expect(safeLockPoints(20, 40), 40, reason: 'en el borde');
      expect(safeLockPoints(21, 40), 0, reason: 'afuera');
      expect(
        safeLockPoints(0, 40) * _rules.safeLocks,
        lessThanOrEqualTo(_rules.safeLockMaxScore),
      );
    });
  });

  group('Puja Secreta', () {
    test('gana la más alta que no se repita', () {
      expect(highestUniqueBid({'ana': 9, 'beto': 9, 'caro': 4}), 'caro');
      expect(highestUniqueBid({'ana': 9, 'beto': 7, 'caro': 4}), 'ana');
    });

    test('si todas se repiten o nadie puja, nadie gana', () {
      expect(highestUniqueBid({'ana': 5, 'beto': 5}), isNull);
      expect(highestUniqueBid({'ana': 0, 'beto': 0}), isNull);
    });

    test('pasar nunca gana', () {
      expect(highestUniqueBid({'ana': 0, 'beto': 3, 'caro': 3}), isNull);
    });
  });
}
