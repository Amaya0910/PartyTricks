import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/stats/firebase_stats_service.dart';
import 'package:party_tricks/services/stats/stats_service.dart';

final statsServiceProvider = Provider<StatsService>(
  (ref) => FirebaseStatsService(FirebaseFirestore.instance),
);

/// La hora actual. En las pruebas se cambia por una fija.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Las estadísticas del jugador con la sesión iniciada, en vivo.
final playerStatsProvider = StreamProvider<PlayerStats>((ref) {
  final uid = ref.watch(userProfileProvider.select((p) => p.value?.uid));
  if (uid == null) return Stream.value(PlayerStats.empty);
  return ref.watch(statsServiceProvider).watchStats(uid);
});
