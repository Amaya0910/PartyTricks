import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/account_rules.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/services/auth/auth_validators.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

/// Cambios de la cuenta desde Ajustes y verificación del correo. Revisa los
/// datos antes de llamar a los servicios. Lanza [AuthException] con el
/// mensaje para mostrar.
class AccountController {
  AccountController(this._ref);

  final Ref _ref;

  UserProfile get _profile {
    final profile = _ref.read(userProfileProvider).value;
    if (profile == null) {
      throw const AuthException('Tu sesión se cerró. Entra de nuevo.');
    }
    return profile;
  }

  DateTime _now() => _ref.read(clockProvider)();

  /// Cambia el nombre de usuario. Solo una vez cada
  /// [AccountRules.usernameCooldown].
  Future<void> changeUsername(String newUsername) {
    return _guard(() async {
      final clean = newUsername.trim();
      final error = AuthValidators.username(clean);
      if (error != null) throw AuthException(error);

      final profile = _profile;
      if (clean == profile.username) {
        throw const AuthException('Ese ya es tu nombre de usuario.');
      }
      final wait = AccountRules.usernameWait(profile.usernameChangedAt, _now());
      if (wait != null) {
        throw AuthException(AccountRules.usernameWaitMessage(wait));
      }
      await _ref
          .read(accountServiceProvider)
          .changeUsername(profile: profile, newUsername: clean, at: _now());
    });
  }

  /// Cambia el código de amistad. Devuelve el nuevo.
  Future<String> regenerateFriendCode() {
    return _guard(
      () => _ref.read(accountServiceProvider).regenerateFriendCode(_profile),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _guard(() async {
      final error =
          AuthValidators.existingPassword(currentPassword) ??
          AuthValidators.newPassword(newPassword) ??
          AuthValidators.confirmPassword(newPassword, confirmPassword);
      if (error != null) throw AuthException(error);
      if (newPassword == currentPassword) {
        throw const AuthException(
          'La nueva contraseña debe ser diferente a la actual.',
        );
      }
      await _ref
          .read(accountServiceProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
    });
  }

  /// Envía el enlace al correo nuevo; el cambio se aplica al abrirlo.
  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) {
    return _guard(() async {
      final error =
          AuthValidators.email(newEmail) ??
          AuthValidators.existingPassword(currentPassword);
      if (error != null) throw AuthException(error);
      if (newEmail.trim().toLowerCase() == _profile.email.toLowerCase()) {
        throw const AuthException('Ese ya es tu correo.');
      }
      await _ref
          .read(accountServiceProvider)
          .changeEmail(currentPassword: currentPassword, newEmail: newEmail);
    });
  }

  Future<void> sendEmailVerification() {
    return _guard(() => _ref.read(authServiceProvider).sendEmailVerification());
  }

  /// Devuelve true si ya verificó el correo.
  Future<bool> checkEmailVerified() {
    return _guard(() => _ref.read(authServiceProvider).reloadEmailVerified());
  }

  Future<void> signOut() => _ref.read(authServiceProvider).signOut();

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException {
      rethrow;
    } catch (error) {
      debugPrint('Cuenta: $error');
      throw const AuthException(
        'No se pudo completar. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }
}

final accountControllerProvider = Provider<AccountController>(
  AccountController.new,
);
