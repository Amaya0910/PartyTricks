import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Mensajes para el jugador según el error de Firebase. Los comparten
/// `FirebaseAuthService` y `FirebaseAccountService`.
class FirebaseErrorMessages {
  const FirebaseErrorMessages._();

  static const String wrongCredentials =
      'Correo, usuario o contraseña incorrectos.';

  static String auth(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Ese correo ya tiene una cuenta.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return wrongCredentials;
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      case 'requires-recent-login':
        return 'Por seguridad, cierra sesión, vuelve a entrar e intenta '
            'de nuevo.';
      case 'account-exists-with-different-credential':
        return 'Ese correo ya tiene una cuenta. Entra con tu contraseña.';
      default:
        return 'No se pudo completar la operación. Intenta de nuevo.';
    }
  }

  static String firestore(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Sin permiso para usar la base de datos. '
            'Revisa las reglas de Firestore.';
      case 'unavailable':
        return 'Sin conexión con la base de datos. Revisa tu internet.';
      default:
        return 'No se pudo acceder a tu perfil. Intenta de nuevo.';
    }
  }
}
