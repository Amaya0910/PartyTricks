import 'package:party_tricks/models/social/friendship.dart';

/// Qué pasó al enviar una solicitud.
enum FriendRequestResult {
  /// Quedó enviada; falta que el otro la acepte.
  sent,

  /// El otro ya me había enviado una: quedamos como amigos.
  accepted,
}

/// Solicitudes y amistades. La versión real usa Cloud Firestore; en las
/// pruebas se puede cambiar por una falsa.
abstract class FriendsService {
  /// Solicitudes y amistades del jugador, en vivo.
  Stream<List<Friendship>> watchFriendships(String uid);

  /// Envía una solicitud de [fromUid] a [toUid]. Lanza `SocialException` si
  /// ya son amigos o si la solicitud ya estaba enviada.
  Future<FriendRequestResult> sendRequest({
    required String fromUid,
    required String toUid,
    required DateTime at,
  });

  /// Acepta la solicitud [friendshipId].
  Future<void> accept(String friendshipId);

  /// Rechaza, cancela o elimina: en los tres casos se borra.
  Future<void> remove(String friendshipId);
}
