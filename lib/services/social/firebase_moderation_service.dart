import 'package:party_tricks/models/social/report_reason.dart';
import 'package:party_tricks/models/social/time_map.dart';
import 'package:party_tricks/services/social/firestore_social_paths.dart';
import 'package:party_tricks/services/social/moderation_service.dart';
import 'package:party_tricks/services/social/pair_id.dart';

/// Bloqueos en `blocks/{bloqueador}_{bloqueado}` y reportes en `reports`.
class FirebaseModerationService implements ModerationService {
  const FirebaseModerationService(this._paths);

  final FirestoreSocialPaths _paths;

  @override
  Stream<Set<String>> watchBlocked(String uid) {
    return _paths.blocks
        .where('blocker', isEqualTo: uid)
        .snapshots()
        .map(
          (query) => {
            for (final doc in query.docs) doc.data()['blocked'] as String,
          },
        );
  }

  @override
  Future<bool> isBlocked({
    required String blockerUid,
    required String uid,
  }) async {
    final id = FirestoreSocialPaths.blockId(blockerUid, uid);
    return (await _paths.blocks.doc(id).get()).exists;
  }

  @override
  Future<void> block({
    required String uid,
    required String otherUid,
    required DateTime at,
  }) {
    // Bloquear y borrar la amistad van juntos.
    final batch = _paths.blocks.firestore.batch();
    batch.set(_paths.blocks.doc(FirestoreSocialPaths.blockId(uid, otherUid)), {
      'blocker': uid,
      'blocked': otherUid,
      'createdAt': TimeMap.write(at),
    });
    batch.delete(_paths.friendships.doc(PairId.of(uid, otherUid)));
    return batch.commit();
  }

  @override
  Future<void> unblock({required String uid, required String otherUid}) {
    return _paths.blocks
        .doc(FirestoreSocialPaths.blockId(uid, otherUid))
        .delete();
  }

  @override
  Future<void> report({
    required String reporterUid,
    required String reportedUid,
    required ReportReason reason,
    required DateTime at,
  }) {
    return _paths.reports.add({
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason.name,
      'chatId': PairId.of(reporterUid, reportedUid),
      'createdAt': TimeMap.write(at),
    });
  }
}
