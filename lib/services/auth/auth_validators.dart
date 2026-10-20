/// Reglas de los datos de la cuenta. Devuelven el mensaje de error o null si
/// el valor es válido, así sirven directo como `validator` de un formulario.
class AuthValidators {
  const AuthValidators._();

  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 16;
  static const int passwordMinLength = 8;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9_]+$');

  static final RegExp _uppercase = RegExp(r'\p{Lu}', unicode: true);
  static final RegExp _lowercase = RegExp(r'\p{Ll}', unicode: true);
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _symbol = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo.';
    if (!_emailPattern.hasMatch(text)) return 'El correo no es válido.';
    return null;
  }

  /// Al iniciar sesión se acepta el correo o el nombre de usuario. Si trae
  /// una arroba se trata como correo y se revisa su formato.
  static String? identifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo o nombre de usuario.';
    if (text.contains('@') && !_emailPattern.hasMatch(text)) {
      return 'El correo no es válido.';
    }
    return null;
  }

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe un nombre de usuario.';
    if (text.length < usernameMinLength) {
      return 'El nombre debe tener al menos $usernameMinLength caracteres.';
    }
    if (text.length > usernameMaxLength) {
      return 'El nombre puede tener máximo $usernameMaxLength caracteres.';
    }
    if (!_usernamePattern.hasMatch(text)) {
      return 'Usa solo letras, números y guion bajo.';
    }
    return null;
  }

  /// Contraseña al crear la cuenta: mínimo 8 caracteres, con una mayúscula,
  /// una minúscula, un número y un símbolo.
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe una contraseña.';
    if (text.length < passwordMinLength) {
      return 'La contraseña debe tener al menos $passwordMinLength caracteres.';
    }
    if (!_uppercase.hasMatch(text)) {
      return 'La contraseña debe incluir una mayúscula.';
    }
    if (!_lowercase.hasMatch(text)) {
      return 'La contraseña debe incluir una minúscula.';
    }
    if (!_digit.hasMatch(text)) {
      return 'La contraseña debe incluir un número.';
    }
    if (!_symbol.hasMatch(text)) {
      return 'La contraseña debe incluir un símbolo (por ejemplo ! o #).';
    }
    return null;
  }

  /// Contraseña al iniciar sesión: solo se pide que no esté vacía (las
  /// cuentas creadas antes de las reglas nuevas deben poder entrar).
  static String? existingPassword(String? value) {
    if (value == null || value.isEmpty) return 'Escribe tu contraseña.';
    return null;
  }

  static String? confirmPassword(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (password != confirmation) return 'Las contraseñas no coinciden.';
    return null;
  }
}
