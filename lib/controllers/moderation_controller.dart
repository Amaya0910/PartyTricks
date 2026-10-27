import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/social_guard.dart';
import 'package:party_tricks/models/social/report_reason.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

/// Bloquear, desbloquear y reportar jugadores (ver `decisiones.md`, D-10).
/// Lanza [SocialException] con el mensaje para mostrar.
class ModerationController {
  ModerationController(this._ref);

  final Ref _ref;

  String get _uid {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) throw const SocialException('Inicia sesión primero.');
    return uid;
  }

  DateTime _now() => _ref.read(clockProvider)();

  /// Bloquea a [otherUid]: deja de ser amigo y ya no puede escribirte,
  /// enviarte solicitudes ni invitarte.
  Future<void> block(String otherUid) {
    return guardSocial(
      () => _ref
          .read(moderationServiceProvider)
          .block(uid: _uid, otherUid: otherUid, at: _now()),
    );
  }

  Future<void> unblock(String otherUid) {
    return guardSocial(
      () => _ref
          .read(moderationServiceProvider)
          .unblock(uid: _uid, otherUid: otherUid),
    );
  }

  Future<void> report(String otherUid, ReportReason reason) {
    return guardSocial(
      () => _ref
          .read(moderationServiceProvider)
          .report(
            reporterUid: _uid,
            reportedUid: otherUid,
            reason: reason,
            at: _now(),
          ),
    );
  }
}

final moderationControllerProvider = Provider<ModerationController>(
  ModerationController.new,
);
