import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:party_tricks/models/auth_user.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/services/auth/firebase_error_messages.dart';
import 'package:party_tricks/services/auth/friend_code_generator.dart';
import 'package:party_tricks/services/auth/google_id_token_source.dart';
import 'package:party_tricks/services/auth/username_reservation.dart';

/// Se usa dentro de la transacción cuando el código de amistad ya existe.
class _FriendCodeTaken implements Exception {
  const _FriendCodeTaken();
}

/// Se usa dentro de la transacción cuando el nombre de usuario ya existe.
class _UsernameTaken implements Exception {
  const _UsernameTaken();
}

/// Cuentas con Firebase Authentication y perfiles en Cloud Firestore.
///
/// Colecciones:
/// - `users/{uid}`: el perfil.
/// - `usernames/{nombre en minúsculas}`: reserva el nombre de usuario. Solo
///   guarda el uid: el correo no se publica (H-01).
/// - `friendCodes/{código}`: reserva el código de amistad.
///
/// Las reservas se crean en la misma transacción que el perfil, así dos
/// personas no pueden quedarse con el mismo nombre o código a la vez.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required this._auth,
    required this._firestore,
    required this._codeGenerator,
    required this._google,
  });

  static const int _maxCodeAttempts = 5;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FriendCodeGenerator _codeGenerator;
  final GoogleIdTokenSource _google;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('usernames');

  CollectionReference<Map<String, dynamic>> get _friendCodes =>
      _firestore.collection('friendCodes');

  @override
  Stream<UserProfile?> watchProfile() {
    late final StreamController<UserProfile?> controller;
    StreamSubscription<User?>? authSubscription;
    StreamSubscription<UserProfile?>? profileSubscription;

    controller = StreamController<UserProfile?>(
      onListen: () {
        authSubscription = _auth.authStateChanges().listen((user) {
          // Cada vez que cambia la sesión se deja de escuchar al jugador
          // anterior y se pasa al nuevo.
          profileSubscription?.cancel();
          profileSubscription = null;

          if (user == null) {
            controller.add(null);
            return;
          }
          profileSubscription = _users
              .doc(user.uid)
              .snapshots()
              .map((snapshot) {
                final data = snapshot.data();
                return data == null
                    ? null
                    : UserProfile.fromMap(snapshot.id, data);
              })
              .listen(controller.add, onError: controller.addError);
        }, onError: controller.addError);
      },
      onCancel: () async {
        await profileSubscription?.cancel();
        await authSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Stream<AuthUser?> watchAuthUser() {
    // userChanges (y no authStateChanges) también avisa al recargar el
    // usuario, por ejemplo cuando verifica el correo.
    return _auth.userChanges().map(_toAuthUser);
  }

  AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
      providers: {for (final info in user.providerData) info.providerId},
    );
  }

  @override
  Future<UserProfile> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final cleanEmail = email.trim();
    final cleanUsername = username.trim();

    final User user;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      user = credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }

    try {
      final profile = await _createProfile(
        uid: user.uid,
        email: cleanEmail,
        username: cleanUsername,
      );
      await _sendVerificationQuietly(user);
      return profile;
    } on _UsernameTaken {
      await _undoRegistration(user);
      throw const AuthException('Ese nombre de usuario ya está en uso.');
    } on FirebaseException catch (e) {
      debugPrint('Registro: error de Firestore ${e.code} ${e.message}');
      await _undoRegistration(user);
      throw AuthException(_firestoreMessage(e));
    } on AuthException {
      await _undoRegistration(user);
      rethrow;
    }
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final User user;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }

    try {
      final snapshot = await _users.doc(user.uid).get();
      final data = snapshot.data();
      if (data == null) {
        await _auth.signOut();
        throw const AuthException('Esta cuenta no tiene perfil de jugador.');
      }
      final profile = await _syncEmail(
        UserProfile.fromMap(snapshot.id, data),
        user,
      );
      await _removeEmailFromReservation(profile);
      return profile;
    } on FirebaseException catch (e) {
      debugPrint('Inicio de sesión: error de Firestore ${e.code} ${e.message}');
      await _auth.signOut();
      throw AuthException(_firestoreMessage(e));
    }
  }

  @override
  Future<GoogleSignInResult> signInWithGoogle() async {
    final String? idToken;
    try {
      idToken = await _google.idToken();
    } catch (error) {
      debugPrint('Google: $error');
      throw const AuthException(
        'No se pudo abrir Google. Revisa tu conexión e intenta de nuevo.',
      );
    }
    if (idToken == null) return GoogleSignInResult.cancelled;

    try {
      // Si el correo ya tenía cuenta con contraseña, Firebase entra a esa
      // misma cuenta (mismo uid), así que conserva su perfil.
      final credential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      final user = credential.user!;
      final snapshot = await _users.doc(user.uid).get();
      final data = snapshot.data();
      if (data == null) return GoogleSignInResult.needsUsername;
      final profile = await _syncEmail(
        UserProfile.fromMap(snapshot.id, data),
        user,
      );
      await _removeEmailFromReservation(profile);
      return GoogleSignInResult.signedIn;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    } on FirebaseException catch (e) {
      debugPrint('Google: error de Firestore ${e.code} ${e.message}');
      await signOut();
      throw AuthException(_firestoreMessage(e));
    }
  }

  @override
  Future<UserProfile> completeProfile({required String username}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Tu sesión se cerró. Entra de nuevo.');
    }
    try {
      return await _createProfile(
        uid: user.uid,
        email: user.email ?? '',
        username: username.trim(),
      );
    } on _UsernameTaken {
      throw const AuthException('Ese nombre de usuario ya está en uso.');
    } on FirebaseException catch (e) {
      debugPrint('Elegir nombre: error de Firestore ${e.code} ${e.message}');
      throw AuthException(_firestoreMessage(e));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<bool> reloadEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Si no había sesión de Google, no importa.
    }
    await _auth.signOut();
  }

  /// Si el jugador cambió su correo (en Ajustes, con el enlace de
  /// verificación), el perfil todavía tiene el viejo: se actualiza aquí.
  Future<UserProfile> _syncEmail(UserProfile profile, User user) async {
    final email = user.email;
    if (email == null || email.isEmpty || email == profile.email) {
      return profile;
    }
    await _users.doc(user.uid).update({'email': email});
    return profile.copyWith(email: email);
  }

  /// El correo de verificación no es crítico: si falla, el jugador puede
  /// pedirlo otra vez desde el aviso.
  Future<void> _sendVerificationQuietly(User user) async {
    try {
      await user.sendEmailVerification();
    } catch (error) {
      debugPrint('No se pudo enviar el correo de verificación: $error');
    }
  }

  /// Las reservas creadas antes de H-01 guardaban el correo (para entrar con
  /// el nombre). Al entrar se le quita a la reserva propia. Si falla, no
  /// importa: el inicio de sesión ya salió bien y se intenta la próxima vez.
  Future<void> _removeEmailFromReservation(UserProfile profile) async {
    final ref = _usernames.doc(profile.username.toLowerCase());
    try {
      final snapshot = await ref.get();
      if (snapshot.data()?.containsKey('email') ?? false) {
        await ref.update({'email': FieldValue.delete()});
      }
    } on FirebaseException catch (e) {
      debugPrint('No se pudo quitar el correo de la reserva: ${e.code}');
    }
  }

  /// Guarda el perfil y reserva el nombre y el código. Si el código de amistad
  /// ya existe, prueba con otro.
  Future<UserProfile> _createProfile({
    required String uid,
    required String email,
    required String username,
  }) async {
    for (var attempt = 0; attempt < _maxCodeAttempts; attempt++) {
      final friendCode = _codeGenerator.generate();
      try {
        return await _firestore.runTransaction((transaction) async {
          final usernameRef = _usernames.doc(username.toLowerCase());
          final codeRef = _friendCodes.doc(friendCode);

          if (await UsernameReservation.isTaken(transaction, usernameRef)) {
            throw const _UsernameTaken();
          }
          final codeSnapshot = await transaction.get(codeRef);
          if (codeSnapshot.exists) throw const _FriendCodeTaken();

          final profile = UserProfile(
            uid: uid,
            email: email,
            username: username,
            friendCode: friendCode,
          );
          transaction.set(usernameRef, UsernameReservation.data(uid));
          transaction.set(codeRef, {'uid': uid});
          transaction.set(_users.doc(uid), profile.toMap());
          return profile;
        });
      } on _FriendCodeTaken {
        continue;
      }
    }
    throw const AuthException(
      'No se pudo crear tu código de amistad. Intenta de nuevo.',
    );
  }

  /// Sin perfil la cuenta quedaría a medias, así que se elimina.
  Future<void> _undoRegistration(User user) async {
    try {
      await user.delete();
    } on FirebaseAuthException {
      await _auth.signOut();
    }
  }

  String _messageFor(FirebaseAuthException error) =>
      FirebaseErrorMessages.auth(error);

  String _firestoreMessage(FirebaseException error) =>
      FirebaseErrorMessages.firestore(error);
}
