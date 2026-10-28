import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

/// De dónde sale el token de Google para entrar a Firebase. Se usa por
/// interfaz para que `FirebaseAuthService` no dependa del paquete de Google
/// y se pueda cambiar en las pruebas.
abstract class GoogleIdTokenSource {
  /// Abre la ventana de Google. Devuelve el token, o null si el jugador la
  /// cerró.
  Future<String?> idToken();

  /// Cierra la sesión de Google, para que la próxima vez pregunte la cuenta.
  Future<void> signOut();
}

/// Versión real con el paquete `google_sign_in`.
///
/// Requisitos (ver `decisiones.md`, D-23): proveedor Google activo en
/// Firebase, huellas SHA-1 y SHA-256 de Android registradas y, en iOS, el
/// esquema de URL del cliente en `Info.plist`.
class GoogleSignInTokenSource implements GoogleIdTokenSource {
  GoogleSignInTokenSource([GoogleSignIn? googleSignIn])
    : _google = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _google;

  /// `initialize` se debe llamar una sola vez.
  Future<void>? _initialized;

  Future<void> _ensureInitialized() => _initialized ??= _google.initialize();

  @override
  Future<String?> idToken() async {
    await _ensureInitialized();
    try {
      final account = await _google.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _google.signOut();
  }
}
