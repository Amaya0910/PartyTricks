import 'dart:math';

import 'package:party_tricks/models/stats/stats_map.dart';

/// Resultados de un minijuego, o de varios juntos.
class MinigameTypeStats {
  const MinigameTypeStats({this.played = 0, this.won = 0, this.bestScore = 0});

  final int played;
  final int won;
  final int bestScore;

  /// Estos resultados más los de [other].
  MinigameTypeStats plus(MinigameTypeStats other) {
    return MinigameTypeStats(
      played: played + other.played,
      won: won + other.won,
      bestScore: max(bestScore, other.bestScore),
    );
  }

  factory MinigameTypeStats.fromMap(Map<String, dynamic> map) {
    return MinigameTypeStats(
      played: StatsMap.readInt(map, 'played'),
      won: StatsMap.readInt(map, 'won'),
      bestScore: StatsMap.readInt(map, 'bestScore'),
    );
  }

  Map<String, dynamic> toMap() => {
    'played': played,
    'won': won,
    'bestScore': bestScore,
  };
}

/// Minijuegos: totales y resultados de cada uno. Se guardan por minijuego para
/// no perder nada si después cambia el tipo de alguno; [groupedBy] los junta.
class MinigameStats {
  const MinigameStats({
    this.won = 0,
    this.lost = 0,
    this.maxWonInMatch = 0,
    this.bestScore = 0,
    this.byType = const {},
  });

  final int won;
  final int lost;

  /// Más minijuegos ganados en una partida.
  final int maxWonInMatch;

  /// Mejor puntaje en cualquier minijuego.
  final int bestScore;

  /// Resultados por id del minijuego.
  final Map<String, MinigameTypeStats> byType;

  int get played => won + lost;

  /// Porcentaje de ganados, redondeado (0 si no ha jugado).
  int get winRate => played == 0 ? 0 : (won * 100 / played).round();

  /// Id del más jugado, o null si no hay ninguno.
  String? get favoriteType => _topBy((stats) => stats.played);

  /// Id del más ganado, o null si no ha ganado ninguno.
  String? get mostWonType => _topBy((stats) => stats.won);

  /// Cuántos distintos ha jugado.
  int get typesPlayed => byType.values.where((s) => s.played > 0).length;

  /// Las mismas estadísticas con [byType] juntado según [groupOf], que dice a
  /// qué grupo va cada id. Los que no tienen grupo no cuentan.
  MinigameStats groupedBy(String? Function(String id) groupOf) {
    final groups = <String, MinigameTypeStats>{};
    byType.forEach((id, stats) {
      final group = groupOf(id);
      if (group == null) return;
      groups[group] = (groups[group] ?? const MinigameTypeStats()).plus(stats);
    });
    return MinigameStats(
      won: won,
      lost: lost,
      maxWonInMatch: maxWonInMatch,
      bestScore: bestScore,
      byType: groups,
    );
  }

  /// El de mayor valor; en un empate, el primero en orden alfabético para
  /// que el resultado no cambie de una vez a otra.
  String? _topBy(int Function(MinigameTypeStats) value) {
    String? best;
    var bestValue = 0;
    final ids = byType.keys.toList()..sort();
    for (final id in ids) {
      final current = value(byType[id]!);
      if (current > bestValue) {
        best = id;
        bestValue = current;
      }
    }
    return best;
  }

  factory MinigameStats.fromMap(Map<String, dynamic> map) {
    final types = StatsMap.readMap(map, 'byType');
    return MinigameStats(
      won: StatsMap.readInt(map, 'won'),
      lost: StatsMap.readInt(map, 'lost'),
      maxWonInMatch: StatsMap.readInt(map, 'maxWonInMatch'),
      bestScore: StatsMap.readInt(map, 'bestScore'),
      byType: {
        for (final id in types.keys)
          id: MinigameTypeStats.fromMap(StatsMap.readMap(types, id)),
      },
    );
  }

  Map<String, dynamic> toMap() => {
    'won': won,
    'lost': lost,
    'maxWonInMatch': maxWonInMatch,
    'bestScore': bestScore,
    'byType': {
      for (final entry in byType.entries) entry.key: entry.value.toMap(),
    },
  };
}
