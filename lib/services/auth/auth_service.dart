import 'package:party_tricks/models/auth_user.dart';
import 'package:party_tricks/models/user_profile.dart';

/// Error de registro o inicio de sesión, con un mensaje para mostrar.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Qué pasó al entrar con Google.
enum GoogleSignInResult {
  /// Entró y ya tenía perfil de jugador.
  signedIn,

  /// Entró por primera vez: falta elegir el nombre de usuario.
  needsUsername,

  /// El jugador cerró la ventana de Google.
  cancelled,
}

/// Registro, inicio de sesión y verificación del correo. La versión real usa
/// Firebase Authentication y Cloud Firestore; en las pruebas se puede cambiar
/// por una falsa.
///
/// Los cambios de la cuenta desde Ajustes (nombre, correo, contraseña,
/// código) están en `AccountService`.
abstract class AuthService {
  /// El perfil del jugador en vivo. Emite null si no hay sesión (o si la
  /// cuenta todavía no tiene perfil). Sigue al jugador activo: si cambia la
  /// sesión, pasa a escuchar el perfil del nuevo jugador.
  Stream<UserProfile?> watchProfile();

  /// La sesión en vivo (también cambia al verificar el correo). Emite null
  /// si no hay sesión.
  Stream<AuthUser?> watchAuthUser();

  /// Crea la cuenta y su perfil, y envía el correo de verificación. Lanza
  /// [AuthException] si el correo o el nombre de usuario ya están en uso, o
  /// si Firebase rechaza los datos. Si algo falla, no queda una cuenta a
  /// medias.
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

  /// Entra con una cuenta de Google. Si el correo ya tenía cuenta con
  /// contraseña, Firebase las une en la misma cuenta.
  Future<GoogleSignInResult> signInWithGoogle();

  /// Crea el perfil de quien entró con Google por primera vez. Lanza
  /// [AuthException] si el nombre ya está en uso.
  Future<UserProfile> completeProfile({required String username});

  /// Vuelve a enviar el correo de verificación.
  Future<void> sendEmailVerification();

  /// Pregunta a Firebase si ya verificó el correo. Devuelve true si sí.
  Future<bool> reloadEmailVerified();

  /// Cierra la sesión (también la de Google).
  Future<void> signOut();
}
