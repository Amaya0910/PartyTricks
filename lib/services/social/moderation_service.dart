import 'package:party_tricks/models/social/report_reason.dart';

/// Bloqueos y reportes (ver `decisiones.md`, D-10). La versión real usa
/// Cloud Firestore; en las pruebas se puede cambiar por una falsa.
abstract class ModerationService {
  /// Uids que [uid] tiene bloqueados, en vivo.
  Stream<Set<String>> watchBlocked(String uid);

  /// Si [blockerUid] bloqueó a [uid].
  Future<bool> isBlocked({required String blockerUid, required String uid});

  /// [uid] bloquea a [otherUid]: también se borra su amistad.
  Future<void> block({
    required String uid,
    required String otherUid,
    required DateTime at,
  });

  /// [uid] desbloquea a [otherUid].
  Future<void> unblock({required String uid, required String otherUid});

  /// Guarda un reporte para que lo revise un adulto o el docente.
  Future<void> report({
    required String reporterUid,
    required String reportedUid,
    required ReportReason reason,
    required DateTime at,
  });
}
