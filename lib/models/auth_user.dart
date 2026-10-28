/// La sesión de Firebase Authentication, sin depender de Firebase: quién
/// entró, si verificó su correo y con qué forma de entrar.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.emailVerified = false,
    this.providers = const {},
  });

  /// Ids de proveedor de Firebase.
  static const passwordProvider = 'password';
  static const googleProvider = 'google.com';

  final String uid;
  final String email;
  final bool emailVerified;

  /// Formas de entrar que tiene la cuenta (correo, Google...).
  final Set<String> providers;

  /// Entra con correo y contraseña: puede cambiar la contraseña y el correo.
  bool get hasPassword => providers.contains(passwordProvider);

  bool get hasGoogle => providers.contains(googleProvider);

  /// Debe ver el aviso de verificar el correo. Google ya verifica el correo.
  bool get needsEmailVerification =>
      hasPassword && !emailVerified && !hasGoogle;
}
