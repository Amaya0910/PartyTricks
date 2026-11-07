/// El contenido de los minijuegos donde cada uno juega por su lado: los dados,
/// lo que cae, las palabras, las cuentas y los cerrojos.
///
/// Sale de la semilla de la partida, así todos los teléfonos juegan
/// exactamente lo mismo y nadie gana por tener un tablero más fácil. Son
/// funciones puras: no dependen de la pantalla ni de Firebase.
library;

/// Azar con semilla: la misma semilla da los mismos números en cualquier
/// teléfono. No se usa `dart:math` porque su secuencia puede cambiar entre
/// versiones; los números caben en un double, así también vale en la web.
class MinigameSequence {
  MinigameSequence(int seed) : _state = seed.abs() % (_modulus - 1) + 1;

  static const int _modulus = 2147483647;
  static const int _multiplier = 48271;

  int _state;

  /// Entero entre [min] y [max], ambos incluidos.
  int next(int min, int max) {
    _state = _state * _multiplier % _modulus;
    return min + _state % (max - min + 1);
  }

  /// Copia de [items] en otro orden.
  List<T> shuffled<T>(List<T> items) {
    final list = [...items];
    for (var i = list.length - 1; i > 0; i--) {
      final j = next(0, i);
      final swap = list[i];
      list[i] = list[j];
      list[j] = swap;
    }
    return list;
  }
}

// -----------------------------------------------------------------------------
// Pulso Perfecto
// -----------------------------------------------------------------------------

/// Cuánto dura cada pulso del ritmo, en ms.
int rhythmBeatMs(int seed, {required int min, required int max}) =>
    MinigameSequence(seed).next(min, max);

/// Cuánto se alejó cada toque del ritmo, en ms. El primero se compara con el
/// pulso que debía seguir ([firstBeatMs]) y los demás con el toque anterior:
/// un mal comienzo no arruina todos los toques.
List<int> rhythmErrors(
  List<int> tapsMs, {
  required int beatMs,
  required int firstBeatMs,
}) {
  return [
    for (var i = 0; i < tapsMs.length; i++)
      i == 0
          ? (tapsMs[0] - firstBeatMs).abs()
          : (tapsMs[i] - tapsMs[i - 1] - beatMs).abs(),
  ];
}

/// Promedio de [errors], redondeado.
int rhythmAverage(List<int> errors) {
  if (errors.isEmpty) return 0;
  return (errors.reduce((a, b) => a + b) / errors.length).round();
}

// -----------------------------------------------------------------------------
// Memoria de Dados
// -----------------------------------------------------------------------------

/// Las caras que hay que recordar. Nunca salen dos iguales seguidas: en la
/// pantalla no se notaría el cambio.
List<int> diceMemoryFaces(int seed, int count) {
  final sequence = MinigameSequence(seed);
  final faces = <int>[];
  while (faces.length < count) {
    final face = sequence.next(1, 6);
    if (faces.isEmpty || faces.last != face) faces.add(face);
  }
  return faces;
}

// -----------------------------------------------------------------------------
// Cazamonedas
// -----------------------------------------------------------------------------

/// Lo que cae en Cazamonedas y cuánto vale.
enum FallingKind {
  coin(1),
  diamond(5),
  bomb(-3);

  const FallingKind(this.points);

  final int points;
}

/// Una pieza que cae.
class FallingItem {
  const FallingItem({
    required this.id,
    required this.kind,
    required this.x,
    required this.startMs,
    required this.fallMs,
  });

  final int id;
  final FallingKind kind;

  /// Dónde cae: de 0 (izquierda) a 1 (derecha).
  final double x;

  /// Cuándo aparece arriba, en ms desde que empieza a jugarse.
  final int startMs;

  /// Cuánto tarda en llegar abajo.
  final int fallMs;
}

/// Todo lo que cae en [playMs]. Cada vez cae más rápido y hay más bombas.
List<FallingItem> coinRainScript(int seed, int playMs) {
  const lanes = 5;
  final sequence = MinigameSequence(seed);
  final items = <FallingItem>[];
  var at = 150;
  var lastLane = -1;
  while (at < playMs - 900) {
    final progress = at / playMs;
    final roll = sequence.next(1, 100);
    final bombShare = 20 + (16 * progress).round();
    final kind = switch (roll) {
      <= 7 => FallingKind.diamond,
      _ when roll <= 7 + bombShare => FallingKind.bomb,
      _ => FallingKind.coin,
    };
    var lane = sequence.next(0, lanes - 1);
    if (lane == lastLane) lane = (lane + 1 + sequence.next(0, 2)) % lanes;
    lastLane = lane;
    final fallMs = (2200 - 900 * progress).round();
    items.add(
      FallingItem(
        id: items.length,
        kind: kind,
        x: (lane + 0.5) / lanes,
        startMs: at,
        // Los diamantes pasan más rápido: hay que estar atento.
        fallMs: kind == FallingKind.diamond ? (fallMs * 0.75).round() : fallMs,
      ),
    );
    at += (sequence.next(240, 400) - 110 * progress).round();
  }
  return items;
}

// -----------------------------------------------------------------------------
// Color Tramposo
// -----------------------------------------------------------------------------

/// Una palabra de Color Tramposo. Los números son posiciones en la lista de
/// colores de la pantalla.
class ColorTrapRound {
  const ColorTrapRound({
    required this.word,
    required this.ink,
    required this.choices,
    required this.flipped,
  });

  /// El color que dice la palabra.
  final int word;

  /// El color con el que está escrita.
  final int ink;

  /// Los botones, en orden.
  final List<int> choices;

  /// Si ahora vale lo que dice la palabra y no el color de la tinta.
  final bool flipped;

  /// El botón correcto.
  int get answer => flipped ? word : ink;
}

/// Las palabras de la partida. A partir de la vuelta [flipFrom] cambia la
/// regla. La palabra nunca coincide con su tinta.
List<ColorTrapRound> colorTrapScript(
  int seed, {
  required int rounds,
  required int flipFrom,
  required int colors,
}) {
  const buttons = 4;
  final sequence = MinigameSequence(seed);
  final all = [for (var i = 0; i < colors; i++) i];
  var last = -1;
  return [
    for (var i = 0; i < rounds; i++)
      () {
        var word = sequence.next(0, colors - 1);
        if (word == last) word = (word + 1) % colors;
        last = word;
        final ink = (word + sequence.next(1, colors - 1)) % colors;
        final others = sequence.shuffled([
          for (final color in all)
            if (color != word && color != ink) color,
        ]);
        return ColorTrapRound(
          word: word,
          ink: ink,
          choices: sequence.shuffled([word, ink, ...others.take(buttons - 2)]),
          flipped: i >= flipFrom,
        );
      }(),
  ];
}

/// Puntos por una palabra correcta: mientras más rápido y más larga la racha
/// (contando esta), más vale.
int colorTrapPoints({
  required int spentMs,
  required int limitMs,
  required int streak,
}) {
  final speed = (limitMs - spentMs).clamp(0, limitMs) / limitMs;
  return 50 + (50 * speed).round() + 10 * streak.clamp(0, 5);
}

// -----------------------------------------------------------------------------
// Cuenta Rápida
// -----------------------------------------------------------------------------

/// Una cuenta con sus dos respuestas posibles.
class MathProblem {
  const MathProblem({
    required this.text,
    required this.left,
    required this.right,
    required this.leftIsRight,
  });

  final String text;
  final int left;
  final int right;

  /// Si la respuesta correcta es la de la izquierda.
  final bool leftIsRight;
}

/// Las cuentas de la partida: empiezan fáciles y se van complicando.
List<MathProblem> quickMathScript(int seed, int count) {
  final sequence = MinigameSequence(seed);
  return [for (var i = 0; i < count; i++) _problem(sequence, i)];
}

MathProblem _problem(MinigameSequence sequence, int index) {
  final String text;
  final int answer;
  if (index < 5) {
    final a = sequence.next(2, 9);
    final b = sequence.next(2, 9);
    text = '$a + $b';
    answer = a + b;
  } else if (index < 12) {
    final a = sequence.next(11, 39);
    final b = sequence.next(3, 9);
    final add = sequence.next(0, 1) == 0;
    text = add ? '$a + $b' : '$a - $b';
    answer = add ? a + b : a - b;
  } else if (index < 22) {
    final a = sequence.next(2, 9);
    final b = sequence.next(3, 9);
    text = '$a × $b';
    answer = a * b;
  } else {
    final a = sequence.next(21, 79);
    final b = sequence.next(12, 19);
    final add = sequence.next(0, 1) == 0;
    text = add ? '$a + $b' : '$a - $b';
    answer = add ? a + b : a - b;
  }
  // La respuesta falsa se parece a la buena para que haya que pensarla.
  final near = sequence.next(1, 3) * (sequence.next(0, 1) == 0 ? 1 : -1);
  final jump = sequence.next(0, 3) == 0 ? 10 : near;
  final wrong = answer + jump <= 0 ? answer + jump.abs() : answer + jump;
  final leftIsRight = sequence.next(0, 1) == 0;
  return MathProblem(
    text: text,
    left: leftIsRight ? answer : wrong,
    right: leftIsRight ? wrong : answer,
    leftIsRight: leftIsRight,
  );
}

/// Puntos por una respuesta correcta, contando esta en la racha.
int quickMathPoints(int streak) => 10 + 2 * (streak - 1).clamp(0, 10);

// -----------------------------------------------------------------------------
// Cofre Fuerte
// -----------------------------------------------------------------------------

/// Un cerrojo: dónde está la marca, qué tan ancha es y cómo gira la aguja.
class SafeLockSetup {
  const SafeLockSetup({
    required this.markDeg,
    required this.widthDeg,
    required this.startDeg,
    required this.turnsPerSecond,
  });

  /// Centro de la marca, en grados (0 arriba, en el sentido del reloj).
  final double markDeg;
  final double widthDeg;

  /// Dónde empieza la aguja.
  final double startDeg;

  /// Vueltas por segundo; negativo si gira al revés.
  final double turnsPerSecond;

  /// Dónde va la aguja a los [ms] de empezar, entre 0 y 360.
  double needleAt(int ms) =>
      (startDeg + 360 * turnsPerSecond * ms / 1000) % 360;
}

/// Los cerrojos: cada uno gira más rápido y tiene la marca más pequeña.
List<SafeLockSetup> safeLockScript(int seed, int count) {
  final sequence = MinigameSequence(seed);
  return [
    for (var i = 0; i < count; i++)
      () {
        final mark = sequence.next(0, 359).toDouble();
        return SafeLockSetup(
          markDeg: mark,
          widthDeg: 54.0 - 16 * i,
          // Siempre lejos de la marca, para que no se gane sin querer.
          startDeg: (mark + sequence.next(120, 240)) % 360,
          turnsPerSecond: (0.42 + 0.2 * i) * (i.isEven ? 1 : -1),
        );
      }(),
  ];
}

/// Qué tan lejos quedó la aguja de la marca, en grados (de 0 a 180).
double safeLockDistance(double needleDeg, double markDeg) {
  final gap = (needleDeg - markDeg).abs() % 360;
  return gap > 180 ? 360 - gap : gap;
}

/// Puntos por detener la aguja a [distanceDeg] de la marca: de 100 en el
/// centro a 40 en el borde, 50 más si fue casi perfecto y 0 si quedó afuera.
int safeLockPoints(double distanceDeg, double widthDeg) {
  final half = widthDeg / 2;
  if (distanceDeg > half) return 0;
  final points = 100 - (60 * distanceDeg / half).round();
  return distanceDeg <= half * 0.2 ? points + 50 : points;
}

// -----------------------------------------------------------------------------
// Puja Secreta
// -----------------------------------------------------------------------------

/// Quién gana una puja: la más alta que nadie más hizo. Las repetidas se
/// anulan y pujar 0 es pasar. Null si nadie gana.
String? highestUniqueBid(Map<String, int> bids) {
  final times = <int, int>{};
  for (final bid in bids.values) {
    if (bid > 0) times[bid] = (times[bid] ?? 0) + 1;
  }
  String? winner;
  var best = 0;
  bids.forEach((id, bid) {
    if (bid > best && times[bid] == 1) {
      winner = id;
      best = bid;
    }
  });
  return winner;
}
