import 'package:party_tricks/models/user_profile.dart';

/// Cambios de la cuenta desde Ajustes. La versión real usa Firebase
/// Authentication y Cloud Firestore; en las pruebas se puede cambiar por
/// una falsa. Los errores llegan como `AuthException` con el mensaje.
abstract class AccountService {
  /// Cambia el nombre de usuario: reserva el nuevo y libera el viejo en la
  /// misma transacción. Lanza `AuthException` si el nombre ya está en uso.
  Future<void> changeUsername({
    required UserProfile profile,
    required String newUsername,
    required DateTime at,
  });

  /// Cambia el código de amistad por uno nuevo y libera el viejo. Devuelve
  /// el código nuevo.
  Future<String> regenerateFriendCode(UserProfile profile);

  /// Cambia la contraseña. Pide la actual porque Firebase lo exige.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Envía un enlace al correo nuevo. El cambio se aplica cuando el jugador
  /// lo abre. Pide la contraseña actual porque Firebase lo exige.
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  });
}
