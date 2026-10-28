import 'package:party_tricks/models/social/chat_summary.dart';
import 'package:party_tricks/models/social/friendship.dart';

/// Las amistades del jugador separadas como se muestran en la pantalla.
class FriendsSections {
  const FriendsSections({
    this.incoming = const [],
    this.friends = const [],
    this.outgoing = const [],
  });

  /// Solicitudes que me enviaron (arriba, con Aceptar y Rechazar).
  final List<Friendship> incoming;

  /// Amigos, el chat más reciente primero.
  final List<Friendship> friends;

  /// Solicitudes que yo envié (abajo, como "Pendiente").
  final List<Friendship> outgoing;

  bool get isEmpty => incoming.isEmpty && friends.isEmpty && outgoing.isEmpty;

  /// Separa [all] desde el punto de vista de [myUid]. Los amigos se ordenan
  /// por el último mensaje de su chat (los que no tienen chat van al final,
  /// por fecha de amistad).
  factory FriendsSections.build({
    required String myUid,
    required List<Friendship> all,
    Map<String, ChatSummary> chats = const {},
  }) {
    DateTime lastActivity(Friendship f) {
      return chats[f.id]?.lastMessage?.sentAt ??
          f.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    final friends = all.where((f) => f.isAccepted).toList()
      ..sort((a, b) => lastActivity(b).compareTo(lastActivity(a)));
    return FriendsSections(
      incoming: [
        for (final f in all)
          if (f.isIncomingFor(myUid)) f,
      ],
      friends: friends,
      outgoing: [
        for (final f in all)
          if (f.isOutgoingFor(myUid)) f,
      ],
    );
  }
}
