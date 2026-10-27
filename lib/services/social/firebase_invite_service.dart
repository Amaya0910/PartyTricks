import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/social/party_invite.dart';
import 'package:party_tricks/services/social/chat_format.dart';
import 'package:party_tricks/services/social/firestore_social_paths.dart';
import 'package:party_tricks/services/social/invite_service.dart';

/// Invitaciones en `invites/{id}`. Cada invitación también se guarda como
/// mensaje del chat, en la misma escritura.
class FirebaseInviteService implements InviteService {
  const FirebaseInviteService(this._paths);

  final FirestoreSocialPaths _paths;

  @override
  Stream<List<PartyInvite>> watchPending(String uid) {
    // Solo filtros de igualdad: no hace falta crear un índice en Firestore.
    return _paths.invites
        .where('toUid', isEqualTo: uid)
        .where('seen', isEqualTo: false)
        .snapshots()
        .map(
          (query) => [
            for (final doc in query.docs)
              PartyInvite.fromMap(doc.id, doc.data()),
          ]..sort((a, b) => a.sentAt.compareTo(b.sentAt)),
        );
  }

  @override
  Future<void> send(PartyInvite invite) {
    final batch = _paths.invites.firestore.batch();
    batch.set(_paths.invites.doc(), invite.toMap());
    _paths.addMessage(
      batch,
      fromUid: invite.fromUid,
      toUid: invite.toUid,
      message: ChatMessage(
        id: '',
        senderId: invite.fromUid,
        type: MessageType.invite,
        text:
            '¡Te invito a mi party! Código '
            '${ChatFormat.roomCode(invite.roomCode)}',
        sentAt: invite.sentAt,
        roomId: invite.roomId,
        roomCode: invite.roomCode,
      ),
    );
    return batch.commit();
  }

  @override
  Future<void> markSeen(String inviteId) {
    return _paths.invites.doc(inviteId).update({'seen': true});
  }
}
