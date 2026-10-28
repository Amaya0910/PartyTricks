import 'package:party_tricks/models/social/public_profile.dart';

/// Perfiles públicos de los jugadores. La versión real usa Cloud Firestore;
/// en las pruebas se puede cambiar por una falsa.
abstract class ProfileDirectory {
  /// El perfil público en vivo. Emite null si el jugador aún no tiene.
  Stream<PublicProfile?> watchProfile(String uid);

  /// Uid del jugador con ese código de amistad, o null si no existe.
  Future<String?> findUidByFriendCode(String code);

  /// Guarda el perfil público del jugador con la sesión iniciada.
  Future<void> publish(PublicProfile profile);
}
