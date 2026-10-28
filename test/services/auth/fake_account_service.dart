import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/account_service.dart';
import 'package:party_tricks/services/auth/auth_service.dart';

/// Cambios de cuenta en memoria para las pruebas.
class FakeAccountService implements AccountService {
  /// Si no es null, la próxima operación lanza este error.
  Object? nextError;

  String? lastUsername;
  DateTime? lastUsernameAt;
  String? lastNewPassword;
  String? lastNewEmail;
  String? lastCurrentPassword;
  int codeCalls = 0;

  /// El código que devuelve [regenerateFriendCode].
  String nextCode = 'NEW234';

  @override
  Future<void> changeUsername({
    required UserProfile profile,
    required String newUsername,
    required DateTime at,
  }) async {
    _throwIfNeeded();
    lastUsername = newUsername;
    lastUsernameAt = at;
  }

  @override
  Future<String> regenerateFriendCode(UserProfile profile) async {
    _throwIfNeeded();
    codeCalls++;
    return nextCode;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _throwIfNeeded();
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
  }

  @override
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    _throwIfNeeded();
    lastCurrentPassword = currentPassword;
    lastNewEmail = newEmail;
  }

  void _throwIfNeeded() {
    final error = nextError;
    if (error == null) return;
    nextError = null;
    if (error is AuthException) throw error;
    throw StateError('$error');
  }
}
