import 'package:party_tricks/models/social/party_invite.dart';

/// Invitaciones a una party. La versión real usa Cloud Firestore; en las
/// pruebas se puede cambiar por una falsa.
abstract class InviteService {
  /// Invitaciones que [uid] aún no ha visto, en vivo (para el aviso).
  Stream<List<PartyInvite>> watchPending(String uid);

  /// Guarda la invitación y la deja también como mensaje en el chat.
  Future<void> send(PartyInvite invite);

  /// El invitado ya vio el aviso.
  Future<void> markSeen(String inviteId);
}
