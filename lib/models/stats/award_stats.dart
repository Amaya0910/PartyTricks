import 'package:party_tricks/models/stats/stats_map.dart';

/// Veces que el jugador ganó cada diamante final (diseno_juego.md, sección
/// 10). También sirve para los premios de una sola partida (0 o 1 cada uno).
class AwardStats {
  const AwardStats({
    this.minigames = 0,
    this.worstLuck = 0,
    this.richest = 0,
    this.topBuyer = 0,
  });

  /// Rey de los minijuegos: el que más minijuegos ganó.
  final int minigames;

  /// Peor suerte: el que más casillas negativas pisó.
  final int worstLuck;

  /// El más rico: el que terminó con más monedas.
  final int richest;

  /// Mayor comprador: el que más compró en las tiendas del mapa.
  final int topBuyer;

  int get total => minigames + worstLuck + richest + topBuyer;

  AwardStats plus(AwardStats other) {
    return AwardStats(
      minigames: minigames + other.minigames,
      worstLuck: worstLuck + other.worstLuck,
      richest: richest + other.richest,
      topBuyer: topBuyer + other.topBuyer,
    );
  }

  factory AwardStats.fromMap(Map<String, dynamic> map) {
    int read(String key) => StatsMap.readInt(map, key);
    return AwardStats(
      minigames: read('minigames'),
      worstLuck: read('worstLuck'),
      richest: read('richest'),
      topBuyer: read('topBuyer'),
    );
  }

  Map<String, dynamic> toMap() => {
    'minigames': minigames,
    'worstLuck': worstLuck,
    'richest': richest,
    'topBuyer': topBuyer,
  };
}
