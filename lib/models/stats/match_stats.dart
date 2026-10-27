import 'package:party_tricks/models/stats/stats_map.dart';

/// Partidas: resultados, podio, rachas de victorias y detalles.
class MatchStats {
  const MatchStats({
    this.won = 0,
    this.lost = 0,
    this.ties = 0,
    this.firstPlaces = 0,
    this.secondPlaces = 0,
    this.thirdPlaces = 0,
    this.currentWinStreak = 0,
    this.maxWinStreak = 0,
    this.maxDiamonds = 0,
    this.maxCoins = 0,
    this.totalDiamonds = 0,
    this.totalCoins = 0,
    this.hosted = 0,
    this.publicMatches = 0,
    this.privateMatches = 0,
    this.roundsPlayed = 0,
    this.longestMatchSeconds = 0,
  });

  final int won;
  final int lost;

  /// Partidas ganadas compartiendo el primer lugar.
  final int ties;

  final int firstPlaces;
  final int secondPlaces;
  final int thirdPlaces;

  /// Partidas ganadas seguidas.
  final int currentWinStreak;
  final int maxWinStreak;

  /// Más diamantes y monedas al final de una partida.
  final int maxDiamonds;
  final int maxCoins;

  /// Diamantes y monedas sumados de todas las partidas.
  final int totalDiamonds;
  final int totalCoins;

  /// Partidas creadas por el jugador (como anfitrión).
  final int hosted;
  final int publicMatches;
  final int privateMatches;
  final int roundsPlayed;
  final int longestMatchSeconds;

  int get played => won + lost;

  /// Porcentaje de ganadas, redondeado (0 si no ha jugado).
  int get winRate => played == 0 ? 0 : (won * 100 / played).round();

  /// Diamantes por partida (0 si no ha jugado).
  double get averageDiamonds => played == 0 ? 0 : totalDiamonds / played;

  factory MatchStats.fromMap(Map<String, dynamic> map) {
    int read(String key) => StatsMap.readInt(map, key);
    return MatchStats(
      won: read('won'),
      lost: read('lost'),
      ties: read('ties'),
      firstPlaces: read('firstPlaces'),
      secondPlaces: read('secondPlaces'),
      thirdPlaces: read('thirdPlaces'),
      currentWinStreak: read('currentWinStreak'),
      maxWinStreak: read('maxWinStreak'),
      maxDiamonds: read('maxDiamonds'),
      maxCoins: read('maxCoins'),
      totalDiamonds: read('totalDiamonds'),
      totalCoins: read('totalCoins'),
      hosted: read('hosted'),
      publicMatches: read('publicMatches'),
      privateMatches: read('privateMatches'),
      roundsPlayed: read('roundsPlayed'),
      longestMatchSeconds: read('longestMatchSeconds'),
    );
  }

  Map<String, dynamic> toMap() => {
    'won': won,
    'lost': lost,
    'ties': ties,
    'firstPlaces': firstPlaces,
    'secondPlaces': secondPlaces,
    'thirdPlaces': thirdPlaces,
    'currentWinStreak': currentWinStreak,
    'maxWinStreak': maxWinStreak,
    'maxDiamonds': maxDiamonds,
    'maxCoins': maxCoins,
    'totalDiamonds': totalDiamonds,
    'totalCoins': totalCoins,
    'hosted': hosted,
    'publicMatches': publicMatches,
    'privateMatches': privateMatches,
    'roundsPlayed': roundsPlayed,
    'longestMatchSeconds': longestMatchSeconds,
  };
}
