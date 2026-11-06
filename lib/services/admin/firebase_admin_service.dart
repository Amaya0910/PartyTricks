import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:party_tricks/models/admin/app_overview.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/shop_stats.dart';
import 'package:party_tricks/models/stats/time_stats.dart';
import 'package:party_tricks/services/admin/admin_service.dart';
import 'package:party_tricks/services/results/match_results_document.dart';
import 'package:party_tricks/services/stats/firestore_stats_document.dart';

/// Panel de administración con Cloud Firestore. Las reglas solo dejan leer
/// `users` y `stats` completos a quien tiene su documento en `admins`.
class FirebaseAdminService implements AdminService {
  FirebaseAdminService(this._firestore);

  final FirebaseFirestore _firestore;

  static const _admins = 'admins';
  static const _users = 'users';

  /// Cuántas partidas recientes se muestran.
  static const _recentLimit = 5;

  @override
  Stream<bool> watchIsAdmin(String uid) {
    return _firestore
        .collection(_admins)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists)
        // Sin permiso o sin conexión, simplemente no es administrador.
        .handleError((Object e) => debugPrint('Admin: $e'));
  }

  @override
  Future<AppOverview> loadOverview() async {
    try {
      final users = await _firestore
          .collection(_users)
          .aggregate(count(), sum('experience'), sum('coins'), sum('diamonds'))
          .get();
      final matchesRef = _firestore.collection(MatchResultsDocument.collection);
      final matches = await matchesRef.count().get();
      final publicMatches = await matchesRef
          .where('isPublic', isEqualTo: true)
          .count()
          .get();
      const minigamesWon = '${PlayerStats.minigamesKey}.won';
      const secondsInApp =
          '${PlayerStats.timeKey}.${TimeStats.secondsInAppKey}';
      const diamondsSpent =
          '${PlayerStats.shopKey}.${ShopStats.diamondsSpentKey}';
      final stats = await _firestore
          .collection(FirestoreStatsDocument.collection)
          .aggregate(sum(minigamesWon), sum(secondsInApp), sum(diamondsSpent))
          .get();
      final recent = await matchesRef
          .orderBy('finishedAt', descending: true)
          .limit(_recentLimit)
          .get();

      int whole(double? value) => (value ?? 0).round();
      return AppOverview(
        users: users.count ?? 0,
        totalExperience: whole(users.getSum('experience')),
        totalCoins: whole(users.getSum('coins')),
        totalDiamonds: whole(users.getSum('diamonds')),
        matches: matches.count ?? 0,
        publicMatches: publicMatches.count ?? 0,
        minigamesWon: whole(stats.getSum(minigamesWon)),
        secondsInApp: whole(stats.getSum(secondsInApp)),
        diamondsSpent: whole(stats.getSum(diamondsSpent)),
        recentMatches: [
          for (final doc in recent.docs)
            MatchResultsDocument.fromMap(doc.data()),
        ],
      );
    } on FirebaseException catch (e) {
      debugPrint('Admin: ${e.code} ${e.message}');
      throw AdminException(
        e.code == 'permission-denied'
            ? 'Sin permiso. ¿Publicaste las reglas de Firestore?'
            : 'No se pudieron cargar las estadísticas. Revisa tu conexión.',
      );
    }
  }

  @override
  Future<void> adjustWallet({
    required String uid,
    int coins = 0,
    int diamonds = 0,
    int extraDice = 0,
  }) async {
    final ref = _firestore.collection(_users).doc(uid);
    try {
      // Se lee y se escribe en una transacción para no bajar de 0.
      await _firestore.runTransaction((transaction) async {
        final data = (await transaction.get(ref)).data() ?? const {};
        int next(String key, int delta) {
          final current = (data[key] as num?)?.toInt() ?? 0;
          return (current + delta).clamp(0, 1 << 31);
        }

        transaction.update(ref, {
          'coins': next('coins', coins),
          'diamonds': next('diamonds', diamonds),
          'extraDice': next('extraDice', extraDice),
        });
      });
    } on FirebaseException catch (e) {
      debugPrint('Admin: ${e.code} ${e.message}');
      throw const AdminException('No se pudo cambiar la cuenta.');
    }
  }

  @override
  Future<void> resetWallet(String uid) async {
    try {
      await _firestore.collection(_users).doc(uid).update({
        'coins': 0,
        'diamonds': 0,
        'extraDice': 0,
      });
    } on FirebaseException catch (e) {
      debugPrint('Admin: ${e.code} ${e.message}');
      throw const AdminException('No se pudo reiniciar la cuenta.');
    }
  }
}
