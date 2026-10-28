import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/services/social/pair_id.dart';

/// Dónde viven amigos, chat e invitaciones en Cloud Firestore. Es el único
/// lugar que conoce estas rutas; lo usan todos los servicios sociales.
///
/// - `publicProfiles/{uid}`: perfil público (sin correo).
/// - `friendships/{parId}`: solicitud o amistad entre dos jugadores.
/// - `chats/{parId}` y `chats/{parId}/messages/{id}`: el chat.
/// - `invites/{id}`: invitaciones a una party (para el aviso).
/// - `blocks/{bloqueador}_{bloqueado}`: bloqueos.
/// - `reports/{id}`: reportes.
class FirestoreSocialPaths {
  const FirestoreSocialPaths(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get publicProfiles =>
      _firestore.collection('publicProfiles');

  CollectionReference<Map<String, dynamic>> get friendCodes =>
      _firestore.collection('friendCodes');

  CollectionReference<Map<String, dynamic>> get friendships =>
      _firestore.collection('friendships');

  CollectionReference<Map<String, dynamic>> get chats =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> get invites =>
      _firestore.collection('invites');

  CollectionReference<Map<String, dynamic>> get blocks =>
      _firestore.collection('blocks');

  CollectionReference<Map<String, dynamic>> get reports =>
      _firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> messages(String chatId) =>
      chats.doc(chatId).collection('messages');

  /// Id del documento de bloqueo de [blocker] a [blocked].
  static String blockId(String blocker, String blocked) =>
      '${blocker}_$blocked';

  /// Agrega a [batch] el mensaje y el resumen del chat, para que el chat y
  /// la lista de amigos se actualicen juntos. La usan el chat y las
  /// invitaciones.
  void addMessage(
    WriteBatch batch, {
    required String fromUid,
    required String toUid,
    required ChatMessage message,
  }) {
    final chatId = PairId.of(fromUid, toUid);
    final data = message.toMap();
    batch.set(messages(chatId).doc(), data);
    batch.set(chats.doc(chatId), {
      'members': PairId.members(fromUid, toUid),
      'lastMessage': data,
    }, SetOptions(merge: true));
  }
}
