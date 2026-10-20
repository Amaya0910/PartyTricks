import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/auth_form_state.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/services/auth/auth_validators.dart';

/// Valida los datos del formulario y llama al servicio de cuentas.
///
/// Los métodos devuelven true si salió bien. Si no, el mensaje queda en
/// [AuthFormState.errorMessage] para que la pantalla lo muestre.
class AuthController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  AuthService get _service => ref.read(authServiceProvider);

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) {
    final error =
        AuthValidators.email(email) ??
        AuthValidators.username(username) ??
        AuthValidators.newPassword(password) ??
        AuthValidators.confirmPassword(password, confirmPassword);
    if (error != null) return _reject(error);

    return _run(
      () => _service.register(
        email: email,
        password: password,
        username: username,
      ),
    );
  }

  /// [identifier] es el correo o el nombre de usuario.
  Future<bool> signIn({required String identifier, required String password}) {
    final error =
        AuthValidators.identifier(identifier) ??
        AuthValidators.existingPassword(password);
    if (error != null) return _reject(error);

    return _run(
      () => _service.signIn(identifier: identifier, password: password),
    );
  }

  Future<void> signOut() => _service.signOut();

  /// Quita el mensaje de error (por ejemplo, al cambiar de pantalla).
  void clearError() => state = const AuthFormState();

  Future<bool> _reject(String message) async {
    state = AuthFormState(errorMessage: message);
    return false;
  }

  Future<bool> _run(Future<Object?> Function() action) async {
    state = const AuthFormState(isLoading: true);
    try {
      await action();
      state = const AuthFormState();
      return true;
    } on AuthException catch (e) {
      state = AuthFormState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthFormState(
        errorMessage: 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
      return false;
    }
  }
}
