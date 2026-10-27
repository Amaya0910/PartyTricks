import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/room_controller.dart';
import 'package:party_tricks/controllers/social_guard.dart';
import 'package:party_tricks/controllers/stats_controller.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/models/social/party_invite.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/rooms/room_service.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

/// Invitar amigos a la party y aceptar invitaciones. Lanza
/// [SocialException] con el mensaje para mostrar.
class InviteController {
  InviteController(this._ref);

  final Ref _ref;

  /// Invita a [friendUids] a [room]. A quien te haya bloqueado no le llega
  /// nada (sin avisarte). Devuelve cuántas invitaciones se enviaron.
  Future<int> invite({required Room room, required List<String> friendUids}) {
    return guardSocial(() async {
      final profile = _ref.read(userProfileProvider).value;
      if (profile == null) {
        throw const SocialException('Inicia sesión primero.');
      }
      final friends = _ref.read(friendUidsProvider);
      final moderation = _ref.read(moderationServiceProvider);
      final invites = _ref.read(inviteServiceProvider);
      final stats = _ref.read(statsControllerProvider);

      var sent = 0;
      for (final friendUid in friendUids) {
        if (!friends.contains(friendUid)) continue;
        final blocked = await moderation.isBlocked(
          blockerUid: friendUid,
          uid: profile.uid,
        );
        if (blocked) continue;
        await invites.send(
          PartyInvite(
            id: '',
            fromUid: profile.uid,
            fromName: profile.username,
            toUid: friendUid,
            roomId: room.id,
            roomCode: room.code,
            sentAt: _ref.read(clockProvider)(),
          ),
        );
        await stats.recordSocial(SocialCounter.inviteSent);
        sent++;
      }
      return sent;
    });
  }

  /// Entra a la sala de la invitación. Devuelve la sala para abrir la sala
  /// de espera.
  Future<Room> accept(String roomCode) async {
    try {
      final room = await _ref
          .read(roomControllerProvider.notifier)
          .joinByCode(roomCode);
      await _ref
          .read(statsControllerProvider)
          .recordSocial(SocialCounter.inviteAccepted);
      return room;
    } on RoomException catch (error) {
      throw SocialException(error.message);
    } on SocialException {
      rethrow;
    } catch (_) {
      throw const SocialException('No se pudo entrar. Intenta de nuevo.');
    }
  }

  /// El aviso ya se mostró. Si falla, no importa: se vuelve a mostrar.
  Future<void> markSeen(String inviteId) async {
    try {
      await _ref.read(inviteServiceProvider).markSeen(inviteId);
    } catch (_) {
      // El aviso se vuelve a mostrar la próxima vez.
    }
  }
}

final inviteControllerProvider = Provider<InviteController>(
  InviteController.new,
);
