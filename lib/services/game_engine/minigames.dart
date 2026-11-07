import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';

/// El tipo de un minijuego: qué hace falta para ganarlo. Es lo que cuentan las
/// estadísticas de "Minijuegos por tipo". El nombre del valor es su id.
enum MinigameCategory {
  reflexes('Reflejos'),
  precision('Precisión'),
  wits('Ingenio'),
  luck('Suerte'),
  strategy('Estrategia');

  const MinigameCategory(this.title);

  final String title;

  /// El tipo con ese id, o null si esta versión no lo conoce.
  static MinigameCategory? byId(Object? id) {
    for (final category in values) {
      if (category.name == id) return category;
    }
    return null;
  }
}

/// Los minijuegos (diseno_juego.md, sección 9). El nombre del valor es el id
/// que se guarda en la partida y en las estadísticas.
enum MinigameType {
  /// Para el Tiempo: parar el reloj lo más cerca posible del objetivo.
  stopwatch('Para el Tiempo', MinigameCategory.precision),

  /// Reacción: tocar apenas sale "¡YA!", sin adelantarse.
  reaction('Reacción', MinigameCategory.reflexes),

  /// Globo Bomba: por turnos se infla el globo; al que se le revienta, sale.
  balloon('Globo Bomba', MinigameCategory.strategy),

  /// Pulso Perfecto: seguir un ritmo que se apaga sin desviarse.
  rhythm('Pulso Perfecto', MinigameCategory.precision),

  /// Memoria de Dados: repetir una fila de dados que cada vez es más larga.
  diceMemory('Memoria de Dados', MinigameCategory.wits),

  /// Cazamonedas: tocar lo que cae, menos las bombas.
  coinRain('Cazamonedas', MinigameCategory.reflexes),

  /// Color Tramposo: tocar el color de la tinta, no el que dice la palabra.
  colorTrap('Color Tramposo', MinigameCategory.wits),

  /// Cuenta Rápida: resolver todas las cuentas que se pueda.
  quickMath('Cuenta Rápida', MinigameCategory.wits),

  /// Cofre Fuerte: detener la aguja en la marca de cada cerrojo.
  safeLock('Cofre Fuerte', MinigameCategory.precision),

  /// Cables Rojos: por turnos se corta un cable; uno hace explotar la bomba.
  wires('Cables Rojos', MinigameCategory.luck),

  /// Puja Secreta: pujar fichas en secreto; gana la más alta que no se repita.
  secretBid('Puja Secreta', MinigameCategory.strategy),

  /// Mayor o Menor: adivinar la siguiente carta o quedar fuera.
  highLow('Mayor o Menor', MinigameCategory.luck),

  /// La Silla Fantasma: elegir silla y rogar que el fantasma no llegue.
  ghostChair('La Silla Fantasma', MinigameCategory.luck);

  const MinigameType(this.title, this.category);

  final String title;
  final MinigameCategory category;

  /// Si su contenido sale de una semilla igual para todos.
  bool get usesSeed => switch (this) {
    rhythm ||
    diceMemory ||
    coinRain ||
    colorTrap ||
    quickMath ||
    safeLock => true,
    _ => false,
  };

  /// Si se juega por vueltas: todos eligen en secreto y luego se revela.
  bool get playsInRounds => switch (this) {
    secretBid || highLow || ghostChair => true,
    _ => false,
  };

  /// Si hace falta alguien contra quien jugar: solo, gana sin jugar.
  bool get needsRivals => playsInRounds || this == balloon || this == wires;

  /// Si gana el que menos saca (y no el que más).
  bool get lowerWins => this == reaction || this == rhythm;

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
    this.minBeatMs = 420,
    this.maxBeatMs = 720,
    this.rhythmDemoBeats = 4,
    this.rhythmTaps = 8,
    this.rhythmLimitMs = 16000,
    this.rhythmMaxError = 2000,
    this.diceMemoryStart = 3,
    this.diceMemoryMax = 15,
    this.diceMemoryLimitMs = 35000,
    this.coinRainMs = 12000,
    this.coinRainMaxScore = 400,
    this.colorTrapRounds = 15,
    this.colorTrapFlipFrom = 10,
    this.colorTrapColors = 6,
    this.colorTrapWordMs = 2200,
    this.colorTrapMaxScore = 2250,
    this.quickMathMs = 15000,
    this.quickMathProblems = 70,
    this.quickMathMaxScore = 5000,
    this.safeLocks = 3,
    this.safeLockTurnMs = 7000,
    this.safeLockMaxScore = 450,
    this.wiresTurnMs = 8000,
    this.wiresBoomMs = 1800,
    this.bidRounds = 3,
    this.bidChips = 15,
    this.maxBid = 10,
    this.bidChoiceMs = 9000,
    this.bidRevealMs = 3600,
    this.minCard = 1,
    this.maxCard = 13,
    this.highLowMaxCards = 9,
    this.highLowChoiceMs = 6000,
    this.highLowRevealMs = 2800,
    this.chairs = 3,
    this.chairLives = 2,
    this.chairMaxStages = 8,
    this.chairChoiceMs = 6000,
    this.chairRevealMs = 4000,
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

  /// Pulso Perfecto: duración de cada pulso, igual para todos.
  final int minBeatMs;
  final int maxBeatMs;

  /// Pulso Perfecto: pulsos que se ven y toques que hay que hacer.
  final int rhythmDemoBeats;
  final int rhythmTaps;

  /// Pulso Perfecto: si no termina en este tiempo, no cuenta.
  final int rhythmLimitMs;

  /// Pulso Perfecto: el mayor desvío que se guarda, en ms.
  final int rhythmMaxError;

  /// Memoria de Dados: largo de la primera fila y el de la última.
  final int diceMemoryStart;
  final int diceMemoryMax;

  /// Memoria de Dados: al llegar a este tiempo, vale lo que lleve.
  final int diceMemoryLimitMs;

  /// Cazamonedas: lo que dura y el mayor puntaje que se acepta.
  final int coinRainMs;
  final int coinRainMaxScore;

  /// Color Tramposo: palabras, desde cuál cambia la regla y cuántos colores.
  final int colorTrapRounds;
  final int colorTrapFlipFrom;
  final int colorTrapColors;

  /// Color Tramposo: tiempo para cada palabra.
  final int colorTrapWordMs;
  final int colorTrapMaxScore;

  /// Cuenta Rápida: lo que dura, las cuentas que hay y el mayor puntaje.
  final int quickMathMs;
  final int quickMathProblems;
  final int quickMathMaxScore;

  /// Cofre Fuerte: cerrojos y tiempo para detener la aguja en cada uno.
  final int safeLocks;
  final int safeLockTurnMs;
  final int safeLockMaxScore;

  /// Cables Rojos: tiempo para cortar y lo que dura la explosión.
  final int wiresTurnMs;
  final int wiresBoomMs;

  /// Puja Secreta: vueltas, fichas para toda la partida y puja más alta.
  final int bidRounds;
  final int bidChips;
  final int maxBid;

  /// Puja Secreta: tiempo para pujar y para ver lo que pujó cada uno.
  final int bidChoiceMs;
  final int bidRevealMs;

  /// Mayor o Menor: los números de las cartas y cuántas pueden salir.
  final int minCard;
  final int maxCard;
  final int highLowMaxCards;

  /// Mayor o Menor: tiempo para elegir y para ver la carta.
  final int highLowChoiceMs;
  final int highLowRevealMs;

  /// La Silla Fantasma: sillas, vidas y vueltas como máximo.
  final int chairs;
  final int chairLives;
  final int chairMaxStages;

  /// La Silla Fantasma: tiempo para elegir y para ver llegar al fantasma.
  final int chairChoiceMs;
  final int chairRevealMs;

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

  /// Hasta cuánto puede valer un puntaje de [type]. Todos caben en lo que
  /// acepta `database.rules.json` (hasta 25000).
  int maxScore(MinigameType type) => switch (type) {
    MinigameType.stopwatch => stopwatchLimitMs,
    MinigameType.reaction => reactionLimitMs,
    MinigameType.balloon => maxPumps,
    MinigameType.rhythm => rhythmMaxError,
    MinigameType.diceMemory => diceMemoryMax,
    MinigameType.coinRain => coinRainMaxScore,
    MinigameType.colorTrap => colorTrapMaxScore,
    MinigameType.quickMath => quickMathMaxScore,
    MinigameType.safeLock => safeLockMaxScore,
    MinigameType.wires => wiresFor(maxPlayers) - 1,
    MinigameType.secretBid ||
    MinigameType.highLow ||
    MinigameType.ghostChair => 999,
  };

  /// Más jugadores en una sala.
  static const maxPlayers = 6;

  /// Cables Rojos: cuántos cables tiene la bomba con [alive] jugadores.
  int wiresFor(int alive) => (alive + 2).clamp(4, maxPlayers + 2);

  /// Por vueltas: tiempo para elegir en [type].
  int choiceMs(MinigameType type) => switch (type) {
    MinigameType.secretBid => bidChoiceMs,
    MinigameType.highLow => highLowChoiceMs,
    _ => chairChoiceMs,
  };

  /// Por vueltas: tiempo para ver lo que pasó en [type].
  int revealMs(MinigameType type) => switch (type) {
    MinigameType.secretBid => bidRevealMs,
    MinigameType.highLow => highLowRevealMs,
    MinigameType.wires => wiresBoomMs,
    _ => chairRevealMs,
  };

  /// Por vueltas: cuántas vueltas se juegan como máximo en [type].
  int maxStages(MinigameType type) => switch (type) {
    MinigameType.secretBid => bidRounds,
    MinigameType.highLow => highLowMaxCards,
    _ => chairMaxStages,
  };

  /// Cuánto espera el anfitrión, desde que ve el paso [step] del minijuego,
  /// antes de cerrarlo por tiempo (o de inflar por quien no juega).
  Duration timeLimit(MinigameState minigame) {
    final type = minigame.type;
    // Ya se sabe quién ganó: solo falta que todos vean cómo terminó.
    if (minigame.ending) return Duration(milliseconds: revealMs(type));
    final ms = switch (type) {
      MinigameType.stopwatch => introMs + stopwatchLimitMs,
      MinigameType.reaction => introMs + minigame.delayMs + reactionLimitMs,
      MinigameType.balloon =>
        (minigame.step == 0 ? introMs : 0) + balloonTurnMs,
      MinigameType.rhythm => introMs + rhythmLimitMs,
      MinigameType.diceMemory => introMs + diceMemoryLimitMs,
      MinigameType.coinRain => introMs + coinRainMs,
      MinigameType.colorTrap => introMs + colorTrapRounds * colorTrapWordMs,
      MinigameType.quickMath => introMs + quickMathMs,
      MinigameType.safeLock => introMs + safeLocks * safeLockTurnMs,
      MinigameType.wires =>
        (minigame.step == 0 ? introMs : wiresBoomMs) + wiresTurnMs,
      MinigameType.secretBid ||
      MinigameType.highLow ||
      MinigameType.ghostChair =>
        (minigame.stage == 0 ? introMs : revealMs(type)) + choiceMs(type),
    };
    return Duration(milliseconds: ms + graceMs);
  }
}

/// Lo que manda quien elige en un minijuego por vueltas. Lleva la vuelta para
/// que una jugada que llegó tarde no cuente en la siguiente.
abstract final class MinigamePick {
  /// No eligió a tiempo.
  static const none = 99;

  static int encode(int stage, int value) => stage * 100 + value;
  static int stageOf(int score) => score ~/ 100;
  static int valueOf(int score) => score % 100;
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
    this.seed = 0,
    this.stage = 0,
    this.wires = 0,
    this.cut = const [],
    this.card = 0,
    this.previousCard = 0,
    this.points = const {},
    this.chips = const {},
    this.picks = const {},
    this.cursed = 0,
    this.ending = false,
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
  /// después del "¡YA!". [MinigameRules.noScore] si no vale. En los juegos
  /// por vueltas, lo que eligió cada uno en la vuelta actual.
  final Map<String, int> scores;

  /// Los que quedaron fuera, en orden (Globo Bomba, Cables Rojos, Mayor o
  /// Menor y La Silla Fantasma).
  final List<String> out;

  /// De aquí sale el contenido de los minijuegos donde cada uno juega por su
  /// lado, para que todos jueguen lo mismo (minigame_content.dart).
  final int seed;

  /// Por vueltas: la vuelta actual. Cables Rojos: la bomba actual.
  final int stage;

  /// Cables Rojos: cuántos cables tiene la bomba y cuáles ya se cortaron.
  final int wires;
  final List<int> cut;

  /// Mayor o Menor: la carta que se ve y la anterior.
  final int card;
  final int previousCard;

  /// Puja Secreta: vueltas ganadas. La Silla Fantasma: vidas que le quedan.
  final Map<String, int> points;

  /// Puja Secreta: fichas que le quedan a cada uno.
  final Map<String, int> chips;

  /// Por vueltas: lo que eligió cada uno en la vuelta que acaba de terminar.
  final Map<String, int> picks;

  /// La Silla Fantasma: la silla a la que llegó el fantasma. Cables Rojos: el
  /// cable que explotó.
  final int cursed;

  /// Ya se sabe cómo termina, pero se deja un momento para que todos lo vean.
  /// El anfitrión lo cierra por tiempo.
  final bool ending;

  /// Globo Bomba y Cables Rojos: a quien le toca ahora.
  String get balloonPlayer => players[turn];

  /// Los que siguen jugando.
  List<String> get alive => [
    for (final id in players)
      if (!out.contains(id)) id,
  ];

  /// Si ya jugaron todos (Para el Tiempo, Reacción y los que se juegan cada
  /// uno por su lado).
  bool get everyonePlayed => players.every(scores.containsKey);

  MinigameState copyWith({
    int? step,
    int? capacity,
    int? pumps,
    int? turn,
    Map<String, int>? scores,
    List<String>? out,
    int? stage,
    int? wires,
    List<int>? cut,
    int? card,
    int? previousCard,
    Map<String, int>? points,
    Map<String, int>? chips,
    Map<String, int>? picks,
    int? cursed,
    bool? ending,
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
      seed: seed,
      stage: stage ?? this.stage,
      wires: wires ?? this.wires,
      cut: cut ?? this.cut,
      card: card ?? this.card,
      previousCard: previousCard ?? this.previousCard,
      points: points ?? this.points,
      chips: chips ?? this.chips,
      picks: picks ?? this.picks,
      cursed: cursed ?? this.cursed,
      ending: ending ?? this.ending,
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

  /// Los puntajes de cada uno, en los minijuegos con puntaje. En Puja Secreta
  /// es `vueltas ganadas × 100 + fichas que le quedaron`.
  final Map<String, int> scores;

  /// Si hubo empate: lo que sacó cada empatado en el dado, en orden.
  final Map<String, List<int>> tiebreak;

  /// En qué orden fueron quedando fuera.
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

  /// Mayor valor de la semilla.
  static const _maxSeed = 1 << 30;

  /// Arma el minijuego de la ronda con sus números al azar. Con menos de
  /// dos jugadores, los que necesitan rivales los gana el que queda sin
  /// jugar.
  MinigameOutcome start(MinigameType type, int round, List<String> players) {
    final takesTurns =
        type == MinigameType.balloon || type == MinigameType.wires;
    final minigame = MinigameState(
      type: type,
      round: round,
      players: players,
      seed: type.usesSeed ? random.nextInt(1, _maxSeed) : 0,
      targetMs: type == MinigameType.stopwatch
          ? random.nextInt(rules.minTargetSeconds, rules.maxTargetSeconds) *
                1000
          : 0,
      delayMs: type == MinigameType.reaction
          ? random.nextInt(rules.minDelayMs, rules.maxDelayMs)
          : 0,
      capacity: type == MinigameType.balloon ? _newCapacity() : 0,
      turn: takesTurns && players.isNotEmpty ? (round - 1) % players.length : 0,
      wires: type == MinigameType.wires ? rules.wiresFor(players.length) : 0,
      // La primera carta nunca es la más alta ni la más baja.
      card: type == MinigameType.highLow
          ? random.nextInt(rules.minCard + 2, rules.maxCard - 2)
          : 0,
      chips: type == MinigameType.secretBid
          ? {for (final id in players) id: rules.bidChips}
          : const {},
      points: type == MinigameType.ghostChair
          ? {for (final id in players) id: rules.chairLives}
          : const {},
    );
    if (type.needsRivals && players.length < 2) {
      return (state: null, result: _result(minigame, players));
    }
    if (players.isEmpty) return (state: null, result: _result(minigame, []));
    return (state: minigame, result: null);
  }

  /// [playerId] juega. Por su lado manda su puntaje (una sola vez); en el
  /// Globo Bomba, cuántas veces infla; en Cables Rojos, qué cable corta; y en
  /// los juegos por vueltas, lo que elige ([MinigamePick]).
  MinigameOutcome play(MinigameState minigame, String playerId, int score) {
    if (!minigame.players.contains(playerId)) {
      throw StateError('$playerId no juega este minijuego');
    }
    if (minigame.ending) throw StateError('El minijuego ya terminó');
    if (minigame.type == MinigameType.balloon) {
      return _inflate(minigame, playerId, score);
    }
    if (minigame.type == MinigameType.wires) {
      return _cutWire(minigame, playerId, score);
    }
    if (minigame.type.playsInRounds) return _pick(minigame, playerId, score);
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

  /// Se acabó el tiempo del paso [step]. Por su lado, los que no jugaron no
  /// valen y se decide. En el Globo Bomba se infla 1 por quien no jugó, en
  /// Cables Rojos se corta uno al azar y en los juegos por vueltas se sigue
  /// sin lo que faltó por elegir.
  MinigameOutcome timeout(MinigameState minigame, int step) {
    if (step != minigame.step) {
      throw StateError('El paso $step ya pasó (va en ${minigame.step})');
    }
    if (minigame.ending) return (state: null, result: _finish(minigame));
    if (minigame.type == MinigameType.balloon) {
      return _inflate(minigame, minigame.balloonPlayer, 1);
    }
    if (minigame.type == MinigameType.wires) {
      final left = [
        for (var wire = 0; wire < minigame.wires; wire++)
          if (!minigame.cut.contains(wire)) wire,
      ];
      final wire = left[random.nextInt(0, left.length - 1)];
      return _cutWire(minigame, minigame.balloonPlayer, wire);
    }
    if (minigame.type.playsInRounds) {
      return _resolve(
        minigame.copyWith(
          step: minigame.step + 1,
          scores: {
            for (final id in minigame.alive)
              id: minigame.scores[id] ?? MinigameRules.noScore,
          },
        ),
      );
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

  /// [playerId] corta un cable. Se decide al cortar si era el malo, así no
  /// queda guardado en la partida: el último siempre lo es. Si explota, sale
  /// y hay bomba nueva para los que quedan.
  MinigameOutcome _cutWire(MinigameState minigame, String playerId, int wire) {
    if (minigame.balloonPlayer != playerId) {
      throw StateError('No es el turno de $playerId en la bomba');
    }
    if (wire < 0 || wire >= minigame.wires || minigame.cut.contains(wire)) {
      throw StateError('El cable $wire no se puede cortar');
    }
    final step = minigame.step + 1;
    final left = minigame.wires - minigame.cut.length;
    if (random.nextInt(1, left) != 1) {
      return (
        state: minigame.copyWith(
          step: step,
          cut: [...minigame.cut, wire],
          turn: _nextAlive(minigame, minigame.out),
        ),
        result: null,
      );
    }
    final out = [...minigame.out, playerId];
    final exploded = minigame.copyWith(step: step, out: out, cursed: wire);
    final alive = exploded.alive.length;
    if (alive <= 1) {
      return (
        state: exploded.copyWith(cut: [...minigame.cut, wire], ending: true),
        result: null,
      );
    }
    return (
      state: exploded.copyWith(
        stage: minigame.stage + 1,
        wires: rules.wiresFor(alive),
        cut: const [],
        turn: _nextAlive(minigame, out),
      ),
      result: null,
    );
  }

  /// [playerId] elige en secreto. Cuando eligieron todos, se resuelve.
  MinigameOutcome _pick(MinigameState minigame, String playerId, int score) {
    if (MinigamePick.stageOf(score) != minigame.stage) {
      throw StateError('Esa jugada era de otra vuelta');
    }
    if (minigame.out.contains(playerId)) {
      throw StateError('$playerId ya quedó fuera');
    }
    if (minigame.scores.containsKey(playerId)) {
      throw StateError('$playerId ya eligió');
    }
    final value = MinigamePick.valueOf(score);
    final none = value == MinigamePick.none;
    if (!none && !_validPick(minigame, playerId, value)) {
      throw StateError('No se puede elegir $value');
    }
    final next = minigame.copyWith(
      step: minigame.step + 1,
      scores: {
        ...minigame.scores,
        playerId: none ? MinigameRules.noScore : value,
      },
    );
    if (!next.alive.every(next.scores.containsKey)) {
      return (state: next, result: null);
    }
    return _resolve(next);
  }

  bool _validPick(MinigameState minigame, String playerId, int value) {
    return switch (minigame.type) {
      MinigameType.secretBid =>
        value >= 0 &&
            value <= rules.maxBid &&
            value <= (minigame.chips[playerId] ?? 0),
      MinigameType.highLow => value == 0 || value == 1,
      _ => value >= 0 && value < rules.chairs,
    };
  }

  /// Todos eligieron (o se acabó el tiempo): pasa a la siguiente vuelta.
  MinigameOutcome _resolve(MinigameState minigame) {
    final next = switch (minigame.type) {
      MinigameType.secretBid => _resolveBid(minigame),
      MinigameType.highLow => _resolveCard(minigame),
      _ => _resolveChair(minigame),
    };
    final stage = minigame.stage + 1;
    final ending =
        next.alive.length <= 1 || stage >= rules.maxStages(minigame.type);
    return (
      state: next.copyWith(stage: stage, scores: const {}, ending: ending),
      result: null,
    );
  }

  /// Gana la vuelta la puja más alta que no se repita. Las fichas pujadas se
  /// gastan aunque se pierda.
  MinigameState _resolveBid(MinigameState minigame) {
    final bids = {
      for (final id in minigame.alive)
        id: minigame.scores[id] == MinigameRules.noScore
            ? 0
            : minigame.scores[id] ?? 0,
    };
    final winner = highestUniqueBid(bids);
    return minigame.copyWith(
      picks: bids,
      chips: {
        for (final id in minigame.alive)
          id: (minigame.chips[id] ?? 0) - (bids[id] ?? 0),
      },
      points: {...minigame.points, ?winner: (minigame.points[winner] ?? 0) + 1},
    );
  }

  /// Sale otra carta. Los que fallaron quedan fuera; si fallaron todos, no
  /// sale nadie y se sigue.
  MinigameState _resolveCard(MinigameState minigame) {
    final current = minigame.card;
    var card = random.nextInt(rules.minCard, rules.maxCard - 1);
    if (card >= current) card++;
    final right = card > current ? 1 : 0;
    final alive = minigame.alive;
    final wrong = [
      for (final id in alive)
        if (minigame.scores[id] != right) id,
    ];
    return minigame.copyWith(
      card: card,
      previousCard: current,
      picks: {for (final id in alive) id: minigame.scores[id] ?? -1},
      out: wrong.length == alive.length ? null : [...minigame.out, ...wrong],
    );
  }

  /// El fantasma llega a una silla al azar y le quita una vida a los que
  /// están ahí. Quien se queda sin vidas sale; si fueran todos los que
  /// quedan, siguen con su última vida.
  MinigameState _resolveChair(MinigameState minigame) {
    final alive = minigame.alive;
    final seats = {
      for (final id in alive)
        id: minigame.scores[id] == MinigameRules.noScore
            ? random.nextInt(0, rules.chairs - 1)
            : minigame.scores[id] ?? 0,
    };
    final cursed = random.nextInt(0, rules.chairs - 1);
    final hit = [
      for (final id in alive)
        if (seats[id] == cursed) id,
    ];
    final lives = {
      ...minigame.points,
      for (final id in hit) id: (minigame.points[id] ?? 1) - 1,
    };
    final dead = [
      for (final id in hit)
        if ((lives[id] ?? 0) <= 0) id,
    ];
    final everyone = dead.length == alive.length;
    return minigame.copyWith(
      picks: seats,
      cursed: cursed,
      points: everyone ? {...lives, for (final id in dead) id: 1} : lives,
      out: everyone ? null : [...minigame.out, ...dead],
    );
  }

  /// Cierra un minijuego que ya terminó de verse.
  MinigameResult _finish(MinigameState minigame) {
    final alive = minigame.alive;
    return switch (minigame.type) {
      MinigameType.secretBid => _bidWinner(minigame),
      MinigameType.ghostChair => _mostOf(minigame, {
        for (final id in alive) id: minigame.points[id] ?? 0,
      }),
      _ =>
        alive.length > 1
            ? _tiebreak(minigame, alive)
            : _result(minigame, alive),
    };
  }

  /// Puja Secreta: gana quien ganó más vueltas; si empatan, quien guardó más
  /// fichas; y si siguen empatados, el dado.
  MinigameResult _bidWinner(MinigameState minigame) {
    final totals = {
      for (final id in minigame.players)
        id: (minigame.points[id] ?? 0) * 100 + (minigame.chips[id] ?? 0),
    };
    return _mostOf(minigame.copyWith(scores: totals), totals);
  }

  /// Gana el de mayor valor en [values]. Si empatan, el dado.
  MinigameResult _mostOf(MinigameState minigame, Map<String, int> values) {
    final best = values.values.reduce((a, b) => a > b ? a : b);
    final tied = [
      for (final id in minigame.players)
        if (values[id] == best) id,
    ];
    if (tied.length == 1) return _result(minigame, tied);
    return _tiebreak(minigame, tied);
  }

  /// Para el Tiempo: gana la menor diferencia con el objetivo. Reacción y
  /// Pulso Perfecto: gana el menor número. En los demás, el mayor puntaje, y
  /// con 0 puntos no se gana. Si empatan, se desempata con el dado.
  MinigameResult _decide(MinigameState minigame) {
    final type = minigame.type;
    final stopwatch = type == MinigameType.stopwatch;
    int distance(int score) => stopwatch
        ? (score - minigame.targetMs).abs()
        : type.lowerWins
        ? score
        : -score;
    final lowest = stopwatch || type.lowerWins ? 0 : 1;
    final valid = {
      for (final MapEntry(key: id, value: score) in minigame.scores.entries)
        if (score >= lowest) id: distance(score),
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
