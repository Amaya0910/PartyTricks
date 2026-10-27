import 'package:party_tricks/models/stats/award_stats.dart';
import 'package:party_tricks/models/stats/board_stats.dart';
import 'package:party_tricks/models/stats/match_stats.dart';
import 'package:party_tricks/models/stats/minigame_stats.dart';
import 'package:party_tricks/models/stats/shop_stats.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/models/stats/stats_map.dart';
import 'package:party_tricks/models/stats/time_stats.dart';

/// Estadísticas permanentes del jugador (Cloud Firestore, `stats/{uid}`).
///
/// Viven aparte del perfil para que guardar el tiempo en la app no reescriba
/// los datos de la cuenta. Cada grupo es un mapa dentro del documento.
class PlayerStats {
  const PlayerStats({
    this.matches = const MatchStats(),
    this.awards = const AwardStats(),
    this.minigames = const MinigameStats(),
    this.board = const BoardStats(),
    this.shop = const ShopStats(),
    this.social = const SocialStats(),
    this.time = const TimeStats(),
  });

  /// Estadísticas de un jugador que todavía no ha jugado.
  static const empty = PlayerStats();

  // Claves de cada grupo en Firestore.
  static const matchesKey = 'matches';
  static const awardsKey = 'awards';
  static const minigamesKey = 'minigames';
  static const boardKey = 'board';
  static const shopKey = 'shop';
  static const socialKey = 'social';
  static const timeKey = 'time';

  final MatchStats matches;
  final AwardStats awards;
  final MinigameStats minigames;
  final BoardStats board;
  final ShopStats shop;
  final SocialStats social;
  final TimeStats time;

  /// Monedas ganadas en total: las de las partidas y las de los cofres.
  int get totalCoinsEarned => matches.totalCoins + shop.coinsFromChests;

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> group(String key) => StatsMap.readMap(map, key);
    return PlayerStats(
      matches: MatchStats.fromMap(group(matchesKey)),
      awards: AwardStats.fromMap(group(awardsKey)),
      minigames: MinigameStats.fromMap(group(minigamesKey)),
      board: BoardStats.fromMap(group(boardKey)),
      shop: ShopStats.fromMap(group(shopKey)),
      social: SocialStats.fromMap(group(socialKey)),
      time: TimeStats.fromMap(group(timeKey)),
    );
  }

  Map<String, dynamic> toMap() => {
    matchesKey: matches.toMap(),
    awardsKey: awards.toMap(),
    minigamesKey: minigames.toMap(),
    boardKey: board.toMap(),
    shopKey: shop.toMap(),
    socialKey: social.toMap(),
    timeKey: time.toMap(),
  };

  PlayerStats copyWith({
    MatchStats? matches,
    AwardStats? awards,
    MinigameStats? minigames,
    BoardStats? board,
    ShopStats? shop,
    SocialStats? social,
    TimeStats? time,
  }) {
    return PlayerStats(
      matches: matches ?? this.matches,
      awards: awards ?? this.awards,
      minigames: minigames ?? this.minigames,
      board: board ?? this.board,
      shop: shop ?? this.shop,
      social: social ?? this.social,
      time: time ?? this.time,
    );
  }
}
