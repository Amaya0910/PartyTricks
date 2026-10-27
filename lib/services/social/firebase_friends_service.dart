import 'package:party_tricks/models/social/friendship.dart';
import 'package:party_tricks/models/social/time_map.dart';
import 'package:party_tricks/services/social/firestore_social_paths.dart';
import 'package:party_tricks/services/social/friends_service.dart';
import 'package:party_tricks/services/social/pair_id.dart';
import 'package:party_tricks/services/social/social_exception.dart';

/// Amistades en `friendships/{parId}`: un solo documento por pareja, con
/// `status` pendiente o aceptada.
class FirebaseFriendsService implements FriendsService {
  const FirebaseFriendsService(this._paths);

  final FirestoreSocialPaths _paths;

  @override
  Stream<List<Friendship>> watchFriendships(String uid) {
    return _paths.friendships
        .where('members', arrayContains: uid)
        .snapshots()
        .map(
          (query) => [
            for (final doc in query.docs)
              Friendship.fromMap(doc.id, doc.data()),
          ],
        );
  }

  @override
  Future<FriendRequestResult> sendRequest({
    required String fromUid,
    required String toUid,
    required DateTime at,
  }) {
    final ref = _paths.friendships.doc(PairId.of(fromUid, toUid));
    // En una transacción: si los dos se envían solicitud a la vez, no quedan
    // dos documentos ni una solicitud pisa a la otra.
    return _paths.friendships.firestore.runTransaction((transaction) async {
      final data = (await transaction.get(ref)).data();
      if (data != null) {
        final current = Friendship.fromMap(ref.id, data);
        if (current.isAccepted) {
          throw const SocialException('Ya son amigos.');
        }
        if (current.requestedBy == fromUid) {
          throw const SocialException('Ya le enviaste una solicitud.');
        }
        // El otro ya me había enviado una: queda aceptada.
        transaction.update(ref, {'status': FriendshipStatus.accepted.name});
        return FriendRequestResult.accepted;
      }
      transaction.set(ref, {
        'members': PairId.members(fromUid, toUid),
        'requestedBy': fromUid,
        'status': FriendshipStatus.pending.name,
        'createdAt': TimeMap.write(at),
      });
      return FriendRequestResult.sent;
    });
  }

  @override
  Future<void> accept(String friendshipId) {
    return _paths.friendships.doc(friendshipId).update({
      'status': FriendshipStatus.accepted.name,
    });
  }

  @override
  Future<void> remove(String friendshipId) {
    return _paths.friendships.doc(friendshipId).delete();
  }
}
