/// Estado de los formularios de registro e inicio de sesión.
class AuthFormState {
  const AuthFormState({this.isLoading = false, this.errorMessage});

  final bool isLoading;

  /// Mensaje para mostrar al jugador, o null si no hay error.
  final String? errorMessage;
}
