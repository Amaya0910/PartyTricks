import 'dart:async';

import 'package:party_tricks/models/match_summary.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/services/stats/stats_service.dart';

/// Servicio de estadísticas en memoria para las pruebas.
class FakeStatsService implements StatsService {
  /// Si no es null, la próxima operación lanza este error.
  Object? nextError;

  final List<(String, MatchSummary)> recordedMatches = [];
  final List<(String, Duration)> appTimes = [];
  final List<(String, DateTime)> activities = [];
  final List<(String, SocialCounter)> socialCounters = [];

  final StreamController<PlayerStats> _stats =
      StreamController<PlayerStats>.broadcast();

  /// Manda [stats] a quien esté escuchando.
  void emit(PlayerStats stats) => _stats.add(stats);

  @override
  Stream<PlayerStats> watchStats(String uid) => _stats.stream;

  @override
  Future<void> recordMatch(String uid, MatchSummary match) async {
    _throwIfNeeded();
    recordedMatches.add((uid, match));
  }

  @override
  Future<void> addAppTime(String uid, Duration time) async {
    _throwIfNeeded();
    appTimes.add((uid, time));
  }

  @override
  Future<void> registerActivity(String uid, DateTime now) async {
    _throwIfNeeded();
    activities.add((uid, now));
  }

  @override
  Future<void> recordSocial(String uid, SocialCounter counter) async {
    _throwIfNeeded();
    socialCounters.add((uid, counter));
  }

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }
}