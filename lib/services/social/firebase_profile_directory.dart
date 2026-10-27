import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/services/social/firestore_social_paths.dart';
import 'package:party_tricks/services/social/profile_directory.dart';

/// Perfiles públicos en `publicProfiles/{uid}`. El código de amistad se
/// busca en `friendCodes/{código}`, que se crea al registrarse.
class FirebaseProfileDirectory implements ProfileDirectory {
  const FirebaseProfileDirectory(this._paths);

  final FirestoreSocialPaths _paths;

  @override
  Stream<PublicProfile?> watchProfile(String uid) {
    return _paths.publicProfiles.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : PublicProfile.fromMap(uid, data);
    });
  }

  @override
  Future<String?> findUidByFriendCode(String code) async {
    final snapshot = await _paths.friendCodes.doc(code).get();
    return snapshot.data()?['uid'] as String?;
  }

  @override
  Future<void> publish(PublicProfile profile) {
    return _paths.publicProfiles.doc(profile.uid).set(profile.toMap());
  }
}
