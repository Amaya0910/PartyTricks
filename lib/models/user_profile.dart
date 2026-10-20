/// Perfil permanente del jugador (vive en Cloud Firestore, colección `users`).
///
/// La contraseña nunca se guarda aquí: la gestiona Firebase Authentication.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    required this.friendCode,
    this.experience = 0,
    this.coins = 0,
    this.diamonds = 0,
  });

  /// Identificador de Firebase Authentication.
  final String uid;
  final String email;

  /// Único (sin distinguir mayúsculas); lo ven los demás jugadores.
  final String username;

  /// Único; sirve para que otros jugadores te agreguen como amigo.
  final String friendCode;

  /// XP acumulada. El nivel se calcula a partir de ella.
  final int experience;

  /// Monedas de la cuenta.
  final int coins;

  /// Diamantes de la cuenta.
  final int diamonds;

  /// El [uid] es el id del documento, por eso no va dentro del mapa.
  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? '',
      friendCode: map['friendCode'] as String? ?? '',
      experience: (map['experience'] as num?)?.toInt() ?? 0,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      diamonds: (map['diamonds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'friendCode': friendCode,
      'experience': experience,
      'coins': coins,
      'diamonds': diamonds,
    };
  }

  UserProfile copyWith({int? experience, int? coins, int? diamonds}) {
    return UserProfile(
      uid: uid,
      email: email,
      username: username,
      friendCode: friendCode,
      experience: experience ?? this.experience,
      coins: coins ?? this.coins,
      diamonds: diamonds ?? this.diamonds,
    );
  }
}
