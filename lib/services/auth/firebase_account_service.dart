import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/account_service.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/services/auth/firebase_error_messages.dart';
import 'package:party_tricks/services/auth/friend_code_generator.dart';

/// Se usa dentro de la transacción cuando el código nuevo ya existe.
class _CodeTaken implements Exception {
  const _CodeTaken();
}

/// Cambios de cuenta con Firebase. Las reservas de nombre (`usernames`) y
/// de código (`friendCodes`) se cambian en la misma transacción que el
/// perfil, como al registrarse (ver `decisiones.md`, D-16).
class FirebaseAccountService implements AccountService {
  FirebaseAccountService({
    required this._auth,
    required this._firestore,
    required this._codeGenerator,
  });

  static const int _maxCodeAttempts = 5;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FriendCodeGenerator _codeGenerator;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _username(String name) =>
      _firestore.collection('usernames').doc(name.toLowerCase());

  DocumentReference<Map<String, dynamic>> _code(String code) =>
      _firestore.collection('friendCodes').doc(code);

  @override
  Future<void> changeUsername({
    required UserProfile profile,
    required String newUsername,
    required DateTime at,
  }) async {
    final oldRef = _username(profile.username);
    final newRef = _username(newUsername);
    // Si solo cambian mayúsculas, la reserva es la misma.
    final sameReservation = oldRef.id == newRef.id;
    try {
      await _firestore.runTransaction((transaction) async {
        if (!sameReservation) {
          if ((await transaction.get(newRef)).exists) {
            throw const AuthException('Ese nombre de usuario ya está en uso.');
          }
          transaction.set(newRef, {'uid': profile.uid, 'email': profile.email});
          transaction.delete(oldRef);
        }
        transaction.update(_user(profile.uid), {
          'username': newUsername,
          'usernameChangedAt': at.millisecondsSinceEpoch,
        });
      });
    } on FirebaseException catch (e) {
      debugPrint('Cambiar nombre: ${e.code} ${e.message}');
      throw AuthException(FirebaseErrorMessages.firestore(e));
    }
  }

  @override
  Future<String> regenerateFriendCode(UserProfile profile) async {
    for (var attempt = 0; attempt < _maxCodeAttempts; attempt++) {
      final code = _codeGenerator.generate();
      try {
        await _firestore.runTransaction((transaction) async {
          final newRef = _code(code);
          if ((await transaction.get(newRef)).exists) throw const _CodeTaken();
          transaction.set(newRef, {'uid': profile.uid});
          transaction.delete(_code(profile.friendCode));
          transaction.update(_user(profile.uid), {'friendCode': code});
        });
        return code;
      } on _CodeTaken {
        continue;
      } on FirebaseException catch (e) {
        debugPrint('Recargar código: ${e.code} ${e.message}');
        throw AuthException(FirebaseErrorMessages.firestore(e));
      }
    }
    throw const AuthException(
      'No se pudo crear un código nuevo. Intenta otra vez.',
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _reauthenticate(currentPassword);
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(FirebaseErrorMessages.auth(e));
    }
  }

  @override
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = await _reauthenticate(currentPassword);
    try {
      await user.verifyBeforeUpdateEmail(newEmail.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(FirebaseErrorMessages.auth(e));
    }
  }

  /// Firebase pide haber entrado hace poco para cambios sensibles: se
  /// confirma con la contraseña actual.
  Future<User> _reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthException('Tu sesión se cerró. Entra de nuevo.');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const AuthException('La contraseña actual no es correcta.');
      }
      throw AuthException(FirebaseErrorMessages.auth(e));
    }
  }
}
