import 'package:party_tricks/models/social/time_map.dart';

/// En qué punto está una amistad.
enum FriendshipStatus { pending, accepted }

/// Una solicitud de amistad o una amistad ya aceptada (Cloud Firestore,
/// `friendships/{id}`). El id es el de la pareja (ver `PairId`), así solo
/// puede haber una entre dos jugadores.
class Friendship {
  const Friendship({
    required this.id,
    required this.members,
    required this.requestedBy,
    required this.status,
    this.createdAt,
  });

  final String id;

  /// Los dos uid, en orden alfabético.
  final List<String> members;

  /// Quién envió la solicitud.
  final String requestedBy;
  final FriendshipStatus status;
  final DateTime? createdAt;

  bool get isAccepted => status == FriendshipStatus.accepted;

  /// El otro jugador, visto desde [myUid].
  String otherOf(String myUid) {
    return members.firstWhere((uid) => uid != myUid, orElse: () => myUid);
  }

  /// Solicitud que me enviaron y que yo debo aceptar o rechazar.
  bool isIncomingFor(String myUid) => !isAccepted && requestedBy != myUid;

  /// Solicitud que yo envié y que el otro aún no acepta.
  bool isOutgoingFor(String myUid) => !isAccepted && requestedBy == myUid;

  factory Friendship.fromMap(String id, Map<String, dynamic> map) {
    return Friendship(
      id: id,
      members: [
        for (final uid in map['members'] as List? ?? const []) uid as String,
      ],
      requestedBy: map['requestedBy'] as String? ?? '',
      status: map['status'] == FriendshipStatus.accepted.name
          ? FriendshipStatus.accepted
          : FriendshipStatus.pending,
      createdAt: TimeMap.read(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'members': members,
    'requestedBy': requestedBy,
    'status': status.name,
    if (createdAt != null) 'createdAt': TimeMap.write(createdAt!),
  };
}
