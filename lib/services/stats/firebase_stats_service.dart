import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_tricks/models/match_summary.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/services/stats/firestore_stats_document.dart';
import 'package:party_tricks/services/stats/stats_calculator.dart';
import 'package:party_tricks/services/stats/stats_service.dart';
import 'package:party_tricks/services/stats/streak_calculator.dart';

/// Estadísticas en Cloud Firestore:
/// - `stats/{uid}`: un mapa por grupo de [PlayerStats].
/// - `stats/{uid}/matches/{matchId}`: marca de cada partida ya sumada, para
///   no contarla dos veces si la pantalla se vuelve a abrir.
/// - `users/{uid}`: la XP, monedas y diamantes que deja cada partida se suman
///   en la misma transacción, así tampoco se cuentan dos veces.
class FirebaseStatsService implements StatsService {
  FirebaseStatsService(
    this._firestore, [
    this._calculator = const StatsCalculator(),
    this._streaks = const StreakCalculator(),
  ]);

  final FirebaseFirestore _firestore;
  final StatsCalculator _calculator;
  final StreakCalculator _streaks;

  DocumentReference<Map<String, dynamic>> _stats(String uid) =>
      FirestoreStatsDocument.ref(_firestore, uid);

  PlayerStats _read(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return data == null ? PlayerStats.empty : PlayerStats.fromMap(data);
  }

  @override
  Stream<PlayerStats> watchStats(String uid) {
    return _stats(uid).snapshots().map(_read);
  }

  @override
  Future<void> recordMatch(String uid, MatchSummary match) {
    final statsRef = _stats(uid);
    final marker = FirestoreStatsDocument.matchMarker(
      _firestore,
      uid,
      match.matchId,
    );
    // Leer la marca y sumar van en la misma transacción: aunque se llame
    // dos veces a la vez, la partida solo se cuenta una.
    return _firestore.runTransaction((transaction) async {
      if ((await transaction.get(marker)).exists) return;
      final current = _read(await transaction.get(statsRef));
      final next = _calculator.applyMatch(current, match);
      transaction.set(statsRef, next.toMap());
      transaction.set(marker, FirestoreStatsDocument.matchMarkerData(match));
      transaction.set(
        FirestoreStatsDocument.profile(_firestore, uid),
        FirestoreStatsDocument.matchRewards(match),
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> addAppTime(String uid, Duration time) {
    // increment no necesita leer antes: no se pierde tiempo si dos
    // escrituras llegan juntas.
    return _stats(uid).set(
      FirestoreStatsDocument.appTimeIncrement(time),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> registerActivity(String uid, DateTime now) {
    final statsRef = _stats(uid);
    return _firestore.runTransaction((transaction) async {
      final current = _read(await transaction.get(statsRef)).time;
      final next = _streaks.registerDay(current, now);
      // Mismo día: no hace falta escribir.
      if (identical(next, current)) return;
      transaction.set(statsRef, {
        PlayerStats.timeKey: next.streakMap(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> recordSocial(String uid, SocialCounter counter) {
    return _stats(uid).set(
      FirestoreStatsDocument.socialIncrement(counter),
      SetOptions(merge: true),
    );
  }
}
