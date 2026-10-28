import 'package:party_tricks/models/social/time_map.dart';

/// Invitación a una party (Cloud Firestore, `invites/{id}`). Sirve para el
/// aviso emergente; en el chat la invitación también queda como mensaje.
class PartyInvite {
  const PartyInvite({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.roomId,
    required this.roomCode,
    required this.sentAt,
    this.seen = false,
  });

  final String id;
  final String fromUid;

  /// Nombre de quien invita, para el aviso.
  final String fromName;
  final String toUid;
  final String roomId;
  final String roomCode;
  final DateTime sentAt;

  /// Si el invitado ya vio el aviso.
  final bool seen;

  factory PartyInvite.fromMap(String id, Map<String, dynamic> map) {
    return PartyInvite(
      id: id,
      fromUid: map['fromUid'] as String? ?? '',
      fromName: map['fromName'] as String? ?? '',
      toUid: map['toUid'] as String? ?? '',
      roomId: map['roomId'] as String? ?? '',
      roomCode: map['roomCode'] as String? ?? '',
      sentAt: TimeMap.read(map['sentAt']) ?? DateTime(2000),
      seen: map['seen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'fromUid': fromUid,
    'fromName': fromName,
    'toUid': toUid,
    'roomId': roomId,
    'roomCode': roomCode,
    'sentAt': TimeMap.write(sentAt),
    'seen': seen,
  };
}
