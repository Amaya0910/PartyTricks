import 'package:party_tricks/models/stats/stats_map.dart';

/// Tiempo de uso (en segundos) y racha de días seguidos abriendo la app.
class TimeStats {
  const TimeStats({
    this.secondsInApp = 0,
    this.secondsPlaying = 0,
    this.secondsInMinigames = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.lastActiveDay,
  });

  static const secondsInAppKey = 'secondsInApp';

  final int secondsInApp;

  /// Dentro de partidas (tablero y minijuegos).
  final int secondsPlaying;
  final int secondsInMinigames;

  final int currentStreak;
  final int maxStreak;

  /// Último día con la app abierta, como `AAAA-MM-DD` (hora del celular).
  final String? lastActiveDay;

  factory TimeStats.fromMap(Map<String, dynamic> map) {
    int read(String key) => StatsMap.readInt(map, key);
    return TimeStats(
      secondsInApp: read(secondsInAppKey),
      secondsPlaying: read('secondsPlaying'),
      secondsInMinigames: read('secondsInMinigames'),
      currentStreak: read('currentStreak'),
      maxStreak: read('maxStreak'),
      lastActiveDay: map['lastActiveDay'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    secondsInAppKey: secondsInApp,
    'secondsPlaying': secondsPlaying,
    'secondsInMinigames': secondsInMinigames,
    'currentStreak': currentStreak,
    'maxStreak': maxStreak,
    'lastActiveDay': lastActiveDay,
  };

  /// Solo los campos de la racha, para guardarlos sin tocar el tiempo.
  Map<String, dynamic> streakMap() => {
    'currentStreak': currentStreak,
    'maxStreak': maxStreak,
    'lastActiveDay': lastActiveDay,
  };

  TimeStats copyWith({
    int? secondsInApp,
    int? secondsPlaying,
    int? secondsInMinigames,
    int? currentStreak,
    int? maxStreak,
    String? lastActiveDay,
  }) {
    return TimeStats(
      secondsInApp: secondsInApp ?? this.secondsInApp,
      secondsPlaying: secondsPlaying ?? this.secondsPlaying,
      secondsInMinigames: secondsInMinigames ?? this.secondsInMinigames,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      lastActiveDay: lastActiveDay ?? this.lastActiveDay,
    );
  }
}
