import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/social/time_map.dart';

/// Resumen de un chat para la lista de amigos (Cloud Firestore, `chats/{id}`):
/// el último mensaje y hasta cuándo leyó cada uno.
class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.members,
    this.lastMessage,
    this.lastReadAt = const {},
  });

  final String id;
  final List<String> members;
  final ChatMessage? lastMessage;

  /// Uid → momento en que abrió el chat por última vez.
  final Map<String, DateTime> lastReadAt;

  /// Si hay un mensaje del otro que [myUid] todavía no ha visto.
  bool hasUnreadFor(String myUid) {
    final last = lastMessage;
    if (last == null || last.senderId == myUid) return false;
    final readAt = lastReadAt[myUid];
    return readAt == null || last.sentAt.isAfter(readAt);
  }

  factory ChatSummary.fromMap(String id, Map<String, dynamic> map) {
    final last = map['lastMessage'];
    final reads = map['lastReadAt'];
    return ChatSummary(
      id: id,
      members: [
        for (final uid in map['members'] as List? ?? const []) uid as String,
      ],
      lastMessage: last is Map
          ? ChatMessage.fromMap('', Map<String, dynamic>.from(last))
          : null,
      lastReadAt: {
        if (reads is Map)
          // `?` deja fuera las fechas que no se pueden leer.
          for (final entry in reads.entries)
            entry.key as String: ?TimeMap.read(entry.value),
      },
    );
  }
}
