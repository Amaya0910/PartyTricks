import 'package:party_tricks/models/user_profile.dart';

/// Error de registro o inicio de sesión, con un mensaje para mostrar.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Operaciones de cuenta. La versión real usa Firebase Authentication y Cloud
/// Firestore; en las pruebas se puede cambiar por una falsa.
abstract class AuthService {
  /// El perfil del jugador en vivo. Emite null si no hay sesión (o si la
  /// cuenta todavía no tiene perfil). Sigue al jugador activo: si cambia la
  /// sesión, pasa a escuchar el perfil del nuevo jugador.
  Stream<UserProfile?> watchProfile();

  /// Crea la cuenta y su perfil. Lanza [AuthException] si el correo o el
  /// nombre de usuario ya están en uso, o si Firebase rechaza los datos.
  /// Si algo falla, no queda una cuenta a medias.
  Future<UserProfile> register({
    required String email,
    required String password,
    required String username,
  });

  /// Inicia sesión con el correo o con el nombre de usuario (sin distinguir
  /// mayúsculas). Lanza [AuthException] si los datos no son correctos.
  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  });

  /// Cierra la sesión.
  Future<void> signOut();
}
