import 'dart:async';

import 'package:party_tricks/models/auth_user.dart';
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
  int googleCalls = 0;
  int verificationEmails = 0;

  /// Lo que devuelve [signInWithGoogle].
  GoogleSignInResult googleResult = GoogleSignInResult.signedIn;

  /// Lo que devuelve [reloadEmailVerified].
  bool emailVerified = false;

  /// El último nombre que llegó a [completeProfile].
  String? completedUsername;

  /// Lo último que se mandó como correo o nombre de usuario al iniciar sesión.
  String? lastIdentifier;

  final StreamController<UserProfile?> _profiles =
      StreamController<UserProfile?>.broadcast();

  final StreamController<AuthUser?> _authUsers =
      StreamController<AuthUser?>.broadcast();

  @override
  Stream<UserProfile?> watchProfile() => _profiles.stream;

  @override
  Stream<AuthUser?> watchAuthUser() => _authUsers.stream;

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
  Future<GoogleSignInResult> signInWithGoogle() async {
    googleCalls++;
    await _beforeResult();
    return googleResult;
  }

  @override
  Future<UserProfile> completeProfile({required String username}) async {
    completedUsername = username;
    await _beforeResult();
    return _profileFor(email: 'jugador@gmail.com', username: username);
  }

  @override
  Future<void> sendEmailVerification() async {
    await _beforeResult();
    verificationEmails++;
  }

  @override
  Future<bool> reloadEmailVerified() async {
    await _beforeResult();
    return emailVerified;
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
