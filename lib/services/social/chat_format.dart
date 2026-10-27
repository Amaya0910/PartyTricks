import 'package:party_tricks/models/social/chat_message.dart';

/// Textos del chat: la hora de cada mensaje y la vista previa en la lista.
class ChatFormat {
  const ChatFormat._();

  /// `14:05` si es de hoy; `27/10 14:05` si es de otro día.
  static String time(DateTime sentAt, DateTime now) {
    final local = sentAt.toLocal();
    final today = now.toLocal();
    final hour = '${_two(local.hour)}:${_two(local.minute)}';
    final sameDay =
        local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
    return sameDay ? hour : '${_two(local.day)}/${_two(local.month)} $hour';
  }

  /// Vista previa del último mensaje en la lista de amigos.
  static String preview(ChatMessage? message, String myUid) {
    if (message == null) return '¡Escríbele!';
    final prefix = message.senderId == myUid ? 'Tú: ' : '';
    if (message.isInvite) return '${prefix}Invitación a una party';
    return '$prefix${message.text}';
  }

  /// Código de sala con guion en medio: `ABC-234`.
  static String roomCode(String code) {
    if (code.length < 2) return code;
    final half = code.length ~/ 2;
    return '${code.substring(0, half)}-${code.substring(half)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
