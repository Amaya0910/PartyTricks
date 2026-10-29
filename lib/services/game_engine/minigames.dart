import 'package:party_tricks/services/game_engine/random_source.dart';

/// Los minijuegos (diseno_juego.md, sección 9). El nombre del valor es el id
/// que se guarda en la partida y en las estadísticas.
enum MinigameType {
  /// Para el Tiempo: parar el reloj lo más cerca posible del objetivo.
  stopwatch('Para el Tiempo'),

  /// Reacción: tocar apenas sale "¡YA!", sin adelantarse.
  reaction('Reacción'),

  /// Globo Bomba: por turnos se infla el globo; al que se le revienta, sale.
  balloon('Globo Bomba');

  const MinigameType(this.title);

  final String title;

  /// El tipo con ese id, o null si esta versión no lo conoce.
  static MinigameType? byId(Object? id) {
    for (final type in values) {
      if (type.name == id) return type;
    }
    return null;
  }
}

/// Tiempos y rangos de los minijuegos. Los usan el motor, el árbitro del
/// anfitrión y la pantalla, así que no se repiten en otro lado.
class MinigameRules {
  const MinigameRules({
    this.introMs = 3000,
    this.minTargetSeconds = 4,
    this.maxTargetSeconds = 19,
    this.stopwatchVisibleMs = 3000,
    this.stopwatchLimitMs = 25000,
    this.minDelayMs = 2000,
    this.maxDelayMs = 7000,
    this.reactionLimitMs = 10000,
    this.minCapacity = 30,
    this.maxCapacity = 70,
    this.maxPumps = 3,
    this.balloonTurnMs = 10000,
    this.graceMs = 5000,
    this.legacyWaitMs = 5000,
    this.maxTiebreakRounds = 20,
  });

  /// Explicación en cada teléfono antes de empezar a contar.
  final int introMs;

  /// Para el Tiempo: el objetivo, en segundos enteros.
  final int minTargetSeconds;
  final int maxTargetSeconds;

  /// Para el Tiempo: cuánto se ve el reloj corriendo antes de esconderse.
  final int stopwatchVisibleMs;

  /// Para el Tiempo: si no toca en este tiempo, no cuenta.
  final int stopwatchLimitMs;

  /// Reacción: espera al azar antes del "¡YA!".
  final int minDelayMs;
  final int maxDelayMs;

  /// Reacción: si no toca en este tiempo después del "¡YA!", no cuenta.
  final int reactionLimitMs;

  /// Globo Bomba: infladas que aguanta cada globo (secreto).
  final int minCapacity;
  final int maxCapacity;

  /// Globo Bomba: infladas por turno, de 1 a este número.
  final int maxPumps;

  /// Globo Bomba: si no infla en este tiempo, el anfitrión infla 1 por él.
  final int balloonTurnMs;

  /// Margen para la red y para el teléfono que tarda en mostrar el
  /// minijuego, antes de que el anfitrión cierre por tiempo.
  final int graceMs;

  /// Partidas guardadas en fase de minijuego sin minijuego armado (de antes
  /// de este bloque): el anfitrión cierra la ronda sin ganador.
  final int legacyWaitMs;

  /// Tope de desempates con el dado; si siguen empatados, ganan todos.
  final int maxTiebreakRounds;

  /// Puntaje de quien no vale: se adelantó, no tocó a tiempo o se fue.
  static const noScore = -1;

  /// Hasta cuántos ms puede valer un puntaje de [type].
  int maxScore(MinigameType type) => switch (type) {
    MinigameType.stopwatch => stopwatchLimitMs,
    MinigameType.reaction => reactionLimitMs,
    MinigameType.balloon => maxPumps,
  };

  /// Cuánto espera el anfitrión, desde que ve el paso [step] del minijuego,
  /// antes de cerrarlo por tiempo (o de inflar por quien no juega).
  Duration timeLimit(MinigameState minigame) {
    final ms = switch (minigame.type) {
      MinigameType.stopwatch => introMs + stopwatchLimitMs,
      MinigameType.reaction => introMs + minigame.delayMs + reactionLimitMs,
      MinigameType.balloon =>
        (minigame.step == 0 ? introMs : 0) + balloonTurnMs,
    };
    return Duration(milliseconds: ms + graceMs);
  }
}

/// El minijuego de la ronda, guardado dentro de la partida
/// (`rooms/{id}/game/minigame`). Así sobrevive a reconexiones y a un cambio
/// de anfitrión.
class MinigameState {
  const MinigameState({
    required this.type,
    required this.round,
    required this.players,
    this.step = 0,
    this.targetMs = 0,
    this.delayMs = 0,
    this.capacity = 0,
    this.pumps = 0,
    this.turn = 0,
    this.scores = const {},
    this.out = const [],
  });

  final MinigameType type;

  /// Ronda en la que se juega; las jugadas de otra ronda se ignoran.
  final int round;

  /// Quiénes juegan, en el orden de turnos. Los ausentes no juegan.
  final List<String> players;

  /// Sube con cada jugada. El árbitro lo usa para no cerrar dos veces.
  final int step;

  /// Para el Tiempo: el objetivo en ms.
  final int targetMs;

  /// Reacción: la espera antes del "¡YA!" en ms.
  final int delayMs;

  /// Globo Bomba: infladas que aguanta el globo actual (secreto en la
  /// pantalla) y las que lleva.
  final int capacity;
  final int pumps;

  /// Globo Bomba: posición en [players] de quien infla.
  final int turn;

  /// Para el Tiempo: ms que dejó correr el reloj. Reacción: ms que tardó
  /// después del "¡YA!". [MinigameRules.noScore] si no vale.
  final Map<String, int> scores;

  /// Globo Bomba: los que reventaron su globo, en orden.
  final List<String> out;

  /// Globo Bomba: quien tiene que inflar ahora.
  String get balloonPlayer => players[turn];

  /// Globo Bomba: los que siguen jugando.
  List<String> get alive => [
    for (final id in players)
      if (!out.contains(id)) id,
  ];

  /// Si ya jugaron todos (Para el Tiempo y Reacción).
  bool get everyonePlayed => players.every(scores.containsKey);

  MinigameState copyWith({
    int? step,
    int? capacity,
    int? pumps,
    int? turn,
    Map<String, int>? scores,
    List<String>? out,
  }) {
    return MinigameState(
      type: type,
      round: round,
      players: players,
      step: step ?? this.step,
      targetMs: targetMs,
      delayMs: delayMs,
      capacity: capacity ?? this.capacity,
      pumps: pumps ?? this.pumps,
      turn: turn ?? this.turn,
      scores: scores ?? this.scores,
      out: out ?? this.out,
    );
  }
}

/// Cómo terminó el minijuego de una ronda. Se guarda en la partida para
/// mostrarlo a todos (`rooms/{id}/game/lastMinigame`).
class MinigameResult {
  const MinigameResult({
    required this.type,
    required this.round,
    required this.winnerIds,
    this.targetMs = 0,
    this.scores = const {},
    this.tiebreak = const {},
    this.out = const [],
  });

  final MinigameType type;
  final int round;

  /// Para el Tiempo: el objetivo en ms.
  final int targetMs;

  /// Puede no haber ganador (nadie tocó a tiempo) o, muy raro, varios.
  final List<String> winnerIds;

  /// Los puntajes de cada uno (Para el Tiempo y Reacción).
  final Map<String, int> scores;

  /// Si hubo empate: lo que sacó cada empatado en el dado, en orden.
  final Map<String, List<int>> tiebreak;

  /// Globo Bomba: en qué orden fueron reventando.
  final List<String> out;
}

/// Lo que devuelve [MinigameJudge]: el minijuego sigue ([state]) o terminó
/// ([result]).
typedef MinigameOutcome = ({MinigameState? state, MinigameResult? result});

/// Las reglas de cada minijuego. No guarda nada: recibe el minijuego y
/// devuelve cómo queda. Lanza [StateError] si la jugada no vale.
class MinigameJudge {
  const MinigameJudge({
    required this.random,
    this.rules = const MinigameRules(),
  });

  final RandomSource random;
  final MinigameRules rules;

  /// Arma el minijuego de la ronda con sus números al azar. Con menos de
  /// dos jugadores, el Globo Bomba lo gana el que queda sin jugar.
  MinigameOutcome start(MinigameType type, int round, List<String> players) {
    final minigame = MinigameState(
      type: type,
      round: round,
      players: players,
      targetMs: type == MinigameType.stopwatch
          ? random.nextInt(rules.minTargetSeconds, rules.maxTargetSeconds) *
                1000
          : 0,
      delayMs: type == MinigameType.reaction
          ? random.nextInt(rules.minDelayMs, rules.maxDelayMs)
          : 0,
      capacity: type == MinigameType.balloon ? _newCapacity() : 0,
      turn: type == MinigameType.balloon && players.isNotEmpty
          ? (round - 1) % players.length
          : 0,
    );
    if (type == MinigameType.balloon && players.length < 2) {
      return (state: null, result: _result(minigame, players));
    }
    if (players.isEmpty) return (state: null, result: _result(minigame, []));
    return (state: minigame, result: null);
  }

  /// [playerId] juega: en Para el Tiempo y Reacción manda su puntaje (una
  /// sola vez); en el Globo Bomba, cuántas veces infla.
  MinigameOutcome play(MinigameState minigame, String playerId, int score) {
    if (!minigame.players.contains(playerId)) {
      throw StateError('$playerId no juega este minijuego');
    }
    if (minigame.type == MinigameType.balloon) {
      return _inflate(minigame, playerId, score);
    }
    if (minigame.scores.containsKey(playerId)) {
      throw StateError('$playerId ya jugó');
    }
    if (score != MinigameRules.noScore &&
        (score < 0 || score > rules.maxScore(minigame.type))) {
      throw StateError('Puntaje fuera de rango: $score');
    }
    final next = minigame.copyWith(
      step: minigame.step + 1,
      scores: {...minigame.scores, playerId: score},
    );
    if (!next.everyonePlayed) return (state: next, result: null);
    return (state: null, result: _decide(next));
  }

  /// Se acabó el tiempo del paso [step]. En Para el Tiempo y Reacción, los
  /// que no jugaron no valen y se decide. En el Globo Bomba, se infla 1 por
  /// quien no jugó.
  MinigameOutcome timeout(MinigameState minigame, int step) {
    if (step != minigame.step) {
      throw StateError('El paso $step ya pasó (va en ${minigame.step})');
    }
    if (minigame.type == MinigameType.balloon) {
      return _inflate(minigame, minigame.balloonPlayer, 1);
    }
    final scores = {
      for (final id in minigame.players)
        id: minigame.scores[id] ?? MinigameRules.noScore,
    };
    return (state: null, result: _decide(minigame.copyWith(scores: scores)));
  }

  MinigameOutcome _inflate(MinigameState minigame, String playerId, int times) {
    if (minigame.balloonPlayer != playerId) {
      throw StateError('No es el turno de $playerId en el globo');
    }
    if (times < 1 || times > rules.maxPumps) {
      throw StateError('Se infla de 1 a ${rules.maxPumps} veces, no $times');
    }
    final pumps = minigame.pumps + times;
    if (pumps < minigame.capacity) {
      return (
        state: minigame.copyWith(
          step: minigame.step + 1,
          pumps: pumps,
          turn: _nextAlive(minigame, minigame.out),
        ),
        result: null,
      );
    }
    // Reventó: sale, y si queda uno solo, ese gana.
    final out = [...minigame.out, playerId];
    final popped = minigame.copyWith(out: out);
    if (popped.alive.length <= 1) {
      return (state: null, result: _result(popped, popped.alive));
    }
    return (
      state: popped.copyWith(
        step: minigame.step + 1,
        capacity: _newCapacity(),
        pumps: 0,
        turn: _nextAlive(minigame, out),
      ),
      result: null,
    );
  }

  /// El siguiente que sigue vivo después de quien infló.
  int _nextAlive(MinigameState minigame, List<String> out) {
    final count = minigame.players.length;
    for (var i = 1; i <= count; i++) {
      final index = (minigame.turn + i) % count;
      if (!out.contains(minigame.players[index])) return index;
    }
    return minigame.turn;
  }

  int _newCapacity() => random.nextInt(rules.minCapacity, rules.maxCapacity);

  /// Para el Tiempo: gana la menor diferencia con el objetivo. Reacción:
  /// gana el más rápido. Si empatan, se desempata con el dado.
  MinigameResult _decide(MinigameState minigame) {
    int distance(int score) => minigame.type == MinigameType.stopwatch
        ? (score - minigame.targetMs).abs()
        : score;
    final valid = {
      for (final MapEntry(key: id, value: score) in minigame.scores.entries)
        if (score >= 0) id: distance(score),
    };
    if (valid.isEmpty) return _result(minigame, []);
    final best = valid.values.reduce((a, b) => a < b ? a : b);
    final tied = [
      for (final id in minigame.players)
        if (valid[id] == best) id,
    ];
    if (tied.length == 1) return _result(minigame, tied);
    return _tiebreak(minigame, tied);
  }

  /// Los empatados lanzan 1d6; el más alto gana. Si vuelven a empatar, se
  /// lanza otra vez entre ellos.
  MinigameResult _tiebreak(MinigameState minigame, List<String> tied) {
    final rolls = <String, List<int>>{for (final id in tied) id: []};
    var left = tied;
    for (var i = 0; i < rules.maxTiebreakRounds && left.length > 1; i++) {
      final round = {for (final id in left) id: random.rollDie()};
      round.forEach((id, value) => rolls[id]!.add(value));
      final top = round.values.reduce((a, b) => a > b ? a : b);
      left = [
        for (final id in left)
          if (round[id] == top) id,
      ];
    }
    return _result(minigame, left, tiebreak: rolls);
  }

  MinigameResult _result(
    MinigameState minigame,
    List<String> winners, {
    Map<String, List<int>> tiebreak = const {},
  }) {
    return MinigameResult(
      type: minigame.type,
      round: minigame.round,
      winnerIds: winners,
      targetMs: minigame.targetMs,
      scores: minigame.scores,
      tiebreak: tiebreak,
      out: minigame.out,
    );
  }
}
