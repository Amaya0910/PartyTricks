/// Reglas de los cambios de cuenta en Ajustes. No dependen de Firebase.
class AccountRules {
  const AccountRules._();

  /// Cada cuánto se puede cambiar el nombre de usuario. Evita que alguien
  /// cambie de nombre seguido para confundir a los demás.
  static const usernameCooldown = Duration(days: 30);

  /// Cuánto falta para poder cambiar el nombre otra vez, o null si ya puede.
  static Duration? usernameWait(DateTime? lastChange, DateTime now) {
    if (lastChange == null) return null;
    final allowedAt = lastChange.add(usernameCooldown);
    if (!now.isBefore(allowedAt)) return null;
    return allowedAt.difference(now);
  }

  /// "Podrás cambiar tu nombre en 3 días." (redondea hacia arriba).
  static String usernameWaitMessage(Duration wait) {
    final hours = wait.inHours;
    final days = (hours / 24).ceil();
    if (days <= 1) return 'Podrás cambiar tu nombre mañana.';
    return 'Podrás cambiar tu nombre en $days días.';
  }
}
