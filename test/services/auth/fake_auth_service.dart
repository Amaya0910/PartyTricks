import 'dart:async';

import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_service.dart';

/// Servicio de cuentas en memoria para las pruebas.
class FakeAuthService implements AuthService {
  /// Si no es null, la próxima operación lanza este error.
  AuthException? nextError;

  /// Si no es null, la próxima operación espera a que se complete.
  Completer<void>? gate;

  int registerCalls = 0;
  int signInCalls = 0;
  int signOutCalls = 0;

  /// Lo último que se mandó como correo o nombre de usuario al iniciar sesión.
  String? lastIdentifier;

  final StreamController<UserProfile?> _profiles =
      StreamController<UserProfile?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile() => _profiles.stream;

  @override
  Future<UserProfile> register({
    required String email,
    required String password,
    required String username,
  }) async {
    registerCalls++;
    await _beforeResult();
    return _profileFor(email: email, username: username);
  }

  @override
  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  }) async {
    signInCalls++;
    lastIdentifier = identifier;
    await _beforeResult();
    return _profileFor(email: 'jugador@correo.com', username: 'jugador');
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  Future<void> _beforeResult() async {
    final pending = gate;
    if (pending != null) {
      gate = null;
      await pending.future;
    }
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
  }

  UserProfile _profileFor({required String email, required String username}) {
    return UserProfile(
      uid: 'uid-1',
      email: email,
      username: username,
      friendCode: 'ABC234',
    );
  }
}
