import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/services/auth/friend_code_generator.dart';

/// Reglas de lo que escribe el jugador en amigos y chat. Devuelven el texto
/// limpio o un mensaje de error; no dependen de Firebase.
class ChatRules {
  const ChatRules._();

  /// Quita espacios de los extremos. Null si queda vacío.
  static String? cleanMessage(String text) {
    final clean = text.trim();
    return clean.isEmpty ? null : clean;
  }

  /// Mensaje de error si el texto no se puede enviar, o null si está bien.
  static String? messageError(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return 'Escribe un mensaje.';
    if (clean.length > ChatMessage.maxLength) {
      return 'Máximo ${ChatMessage.maxLength} caracteres.';
    }
    return null;
  }

  /// Limpia un código de amistad: sin espacios ni guion, en mayúsculas.
  static String normalizeFriendCode(String code) {
    return code.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
  }

  /// Mensaje de error si el código no es válido, o null si está bien.
  static String? friendCodeError(String code) {
    final clean = normalizeFriendCode(code);
    final valid =
        clean.length == FriendCodeGenerator.length &&
        clean.split('').every(FriendCodeGenerator.alphabet.contains);
    return valid ? null : 'El código no es válido.';
  }
}
