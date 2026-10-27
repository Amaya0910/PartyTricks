import 'dart:math';

/// Fuente de azar del motor del juego.
///
/// Se usa por interfaz para que en las pruebas se puedan fijar los dados.
abstract class RandomSource {
  /// Entero entre [min] y [max], ambos incluidos.
  int nextInt(int min, int max);

  /// Lanza un dado de [sides] caras (1 a [sides]).
  int rollDie([int sides = 6]) => nextInt(1, sides);
}

/// Azar real, para la partida de verdad.
class DartRandomSource extends RandomSource {
  DartRandomSource([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  int nextInt(int min, int max) => min + _random.nextInt(max - min + 1);
}
