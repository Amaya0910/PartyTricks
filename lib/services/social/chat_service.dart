import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/social/chat_summary.dart';

/// Chats entre amigos. La versión real usa Cloud Firestore; en las pruebas
/// se puede cambiar por una falsa.
abstract class ChatService {
  /// Los chats del jugador (para la lista de amigos), en vivo.
  Stream<List<ChatSummary>> watchChats(String uid);

  /// Los últimos mensajes de un chat, del más viejo al más nuevo, en vivo.
  Stream<List<ChatMessage>> watchMessages(String chatId);

  /// Envía [message] de [fromUid] a [toUid].
  Future<void> send({
    required String fromUid,
    required String toUid,
    required ChatMessage message,
  });

  /// Marca el chat como leído por [uid] hasta [at].
  Future<void> markRead({
    required String chatId,
    required String uid,
    required DateTime at,
  });
}
