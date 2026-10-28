import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/social/chat_summary.dart';
import 'package:party_tricks/models/social/time_map.dart';
import 'package:party_tricks/services/social/chat_service.dart';
import 'package:party_tricks/services/social/firestore_social_paths.dart';

/// Chats en `chats/{parId}` (resumen) y `chats/{parId}/messages` (mensajes).
class FirebaseChatService implements ChatService {
  const FirebaseChatService(this._paths, {this.messageLimit = 100});

  final FirestoreSocialPaths _paths;

  /// Cuántos mensajes recientes se cargan.
  final int messageLimit;

  @override
  Stream<List<ChatSummary>> watchChats(String uid) {
    return _paths.chats
        .where('members', arrayContains: uid)
        .snapshots()
        .map(
          (query) => [
            for (final doc in query.docs)
              ChatSummary.fromMap(doc.id, doc.data()),
          ],
        );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _paths
        .messages(chatId)
        .orderBy('sentAt', descending: true)
        .limit(messageLimit)
        .snapshots()
        .map(
          (query) => [
            // Llegan del más nuevo al más viejo; se voltean para mostrarlos.
            for (final doc in query.docs.reversed)
              ChatMessage.fromMap(doc.id, doc.data()),
          ],
        );
  }

  @override
  Future<void> send({
    required String fromUid,
    required String toUid,
    required ChatMessage message,
  }) {
    final batch = _paths.chats.firestore.batch();
    _paths.addMessage(batch, fromUid: fromUid, toUid: toUid, message: message);
    return batch.commit();
  }

  @override
  Future<void> markRead({
    required String chatId,
    required String uid,
    required DateTime at,
  }) {
    return _paths.chats.doc(chatId).set({
      'lastReadAt': {uid: TimeMap.write(at)},
    }, SetOptions(merge: true));
  }
}
