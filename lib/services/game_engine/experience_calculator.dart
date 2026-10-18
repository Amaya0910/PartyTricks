import 'dart:math';

/// Experiencia por partida y curva de niveles (diseno_juego.md, sección 11).
class ExperienceCalculator {
  const ExperienceCalculator();

  /// XP base según el puesto. Solo los 3 primeros ganan.
  static const _baseXp = {1: 100, 2: 60, 3: 30};

  /// XP que gana un jugador al terminar la partida.
  ///
  /// [place] es el puesto (1, 2, 3...). En un empate, a todos los empatados
  /// se les pasa el puesto más alto. Un jugador desconectado recibe 0.
  int xpForMatch({
    required int place,
    required int players,
    required int rounds,
    bool disconnected = false,
  }) {
    final base = _baseXp[place];
    if (disconnected || base == null) return 0;
    // base × (1 + 0.15 × (jugadores − 2)) × (0.5 + rondas / 20), redondeado,
    // escrito con enteros: base × (20 + 3(j − 2)) × (10 + r) / 400.
    final numerator = base * (20 + 3 * (players - 2)) * (10 + rounds);
    return (numerator + 200) ~/ 400;
  }

  /// XP necesaria para subir del nivel [level] al siguiente.
  int xpToNextLevel(int level) => (50 + 25 * pow(level, 1.5)).round();

  /// Nivel que corresponde a la XP acumulada. Se empieza en el nivel 1.
  int levelForXp(int totalXp) {
    var level = 1;
    var remaining = totalXp;
    while (remaining >= xpToNextLevel(level)) {
      remaining -= xpToNextLevel(level);
      level++;
    }
    return level;
  }
}
