/// Datos del jugador que pueden ver los demás (Cloud Firestore,
/// `publicProfiles/{uid}`).
///
/// Es una copia reducida de `users/{uid}` sin el correo, para que los amigos
/// vean el nombre y el nivel sin poder leer datos privados.
class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.username,
    this.friendCode = '',
    this.experience = 0,
    this.photoUrl,
  });

  final String uid;
  final String username;
  final String friendCode;

  /// XP acumulada; el nivel se calcula con `ExperienceCalculator`.
  final int experience;

  /// Foto de perfil (opcional).
  final String? photoUrl;

  factory PublicProfile.fromMap(String uid, Map<String, dynamic> map) {
    return PublicProfile(
      uid: uid,
      username: map['username'] as String? ?? '',
      friendCode: map['friendCode'] as String? ?? '',
      experience: (map['experience'] as num?)?.toInt() ?? 0,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'username': username,
    'friendCode': friendCode,
    'experience': experience,
    'photoUrl': photoUrl,
  };

  /// Si guardar [other] cambiaría algo (para no escribir de más).
  bool sameAs(PublicProfile other) {
    return uid == other.uid &&
        username == other.username &&
        friendCode == other.friendCode &&
        experience == other.experience &&
        photoUrl == other.photoUrl;
  }
}
