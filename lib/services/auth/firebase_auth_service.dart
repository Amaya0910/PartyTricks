import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/services/auth/friend_code_generator.dart';

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
/// - `usernames/{nombre en minúsculas}`: reserva el nombre de usuario y guarda
///   el correo, para poder iniciar sesión con el nombre.
/// - `friendCodes/{código}`: reserva el código de amistad.
///
/// Las reservas se crean en la misma transacción que el perfil, así dos
/// personas no pueden quedarse con el mismo nombre o código a la vez.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required this._auth,
    required this._firestore,
    required this._codeGenerator,
  });

  static const int _maxCodeAttempts = 5;

  static const String _wrongCredentials =
      'Correo, usuario o contraseña incorrectos.';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FriendCodeGenerator _codeGenerator;

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
      return await _createProfile(
        uid: user.uid,
        email: cleanEmail,
        username: cleanUsername,
      );
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
    required String identifier,
    required String password,
  }) async {
    final email = await _resolveEmail(identifier);

    final User user;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
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
      final profile = UserProfile.fromMap(snapshot.id, data);
      await _publishEmailForUsernameLogin(profile);
      return profile;
    } on FirebaseException catch (e) {
      debugPrint('Inicio de sesión: error de Firestore ${e.code} ${e.message}');
      await _auth.signOut();
      throw AuthException(_firestoreMessage(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Devuelve el correo para autenticar: el mismo texto si es un correo, o el
  /// que está guardado junto al nombre de usuario (sin distinguir mayúsculas).
  Future<String> _resolveEmail(String identifier) async {
    final text = identifier.trim();
    if (text.contains('@')) return text;

    try {
      final snapshot = await _usernames.doc(text.toLowerCase()).get();
      final email = snapshot.data()?['email'] as String?;
      if (email == null || email.isEmpty) {
        throw const AuthException(_wrongCredentials);
      }
      return email;
    } on FirebaseException catch (e) {
      debugPrint('Búsqueda de usuario: ${e.code} ${e.message}');
      throw AuthException(_firestoreMessage(e));
    }
  }

  /// Las cuentas creadas antes de poder entrar con el nombre de usuario no
  /// guardaron su correo en la reserva. Se completa al iniciar sesión con el
  /// correo. Si falla, no importa: el inicio de sesión ya salió bien.
  Future<void> _publishEmailForUsernameLogin(UserProfile profile) async {
    try {
      await _usernames.doc(profile.username.toLowerCase()).set({
        'uid': profile.uid,
        'email': profile.email,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('No se pudo guardar el correo del usuario: ${e.code}');
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

          final usernameSnapshot = await transaction.get(usernameRef);
          if (usernameSnapshot.exists) throw const _UsernameTaken();
          final codeSnapshot = await transaction.get(codeRef);
          if (codeSnapshot.exists) throw const _FriendCodeTaken();

          final profile = UserProfile(
            uid: uid,
            email: email,
            username: username,
            friendCode: friendCode,
          );
          transaction.set(usernameRef, {'uid': uid, 'email': email});
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

  String _messageFor(FirebaseAuthException error) {
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
        return _wrongCredentials;
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'No se pudo completar la operación. Intenta de nuevo.';
    }
  }

  String _firestoreMessage(FirebaseException error) {
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
