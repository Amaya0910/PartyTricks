import 'package:party_tricks/models/social/time_map.dart';

/// Tipo de mensaje del chat.
enum MessageType {
  /// Texto escrito por el jugador.
  text,

  /// Invitación a una party, con botón para unirse.
  invite,
}

/// Un mensaje del chat entre dos amigos (Cloud Firestore,
/// `chats/{id}/messages/{messageId}`).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.type = MessageType.text,
    this.roomId,
    this.roomCode,
  });

  /// Largo máximo de un mensaje de texto.
  static const maxLength = 200;

  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final MessageType type;

  /// Solo en invitaciones: la sala a la que invita.
  final String? roomId;
  final String? roomCode;

  bool get isInvite => type == MessageType.invite;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      sentAt: TimeMap.read(map['sentAt']) ?? DateTime(2000),
      type: map['type'] == MessageType.invite.name
          ? MessageType.invite
          : MessageType.text,
      roomId: map['roomId'] as String?,
      roomCode: map['roomCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'sentAt': TimeMap.write(sentAt),
    'type': type.name,
    if (roomId != null) 'roomId': roomId,
    if (roomCode != null) 'roomCode': roomCode,
  };
}
