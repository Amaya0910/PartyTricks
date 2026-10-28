/// Preferencias del jugador en este celular (pantalla de Ajustes).
///
/// Por ahora no hay sonidos ni notificaciones: los interruptores se guardan
/// para que estén listos cuando existan.
class AppPreferences {
  const AppPreferences({
    this.notifications = true,
    this.sound = true,
    this.soundEffects = true,
    this.languageCode = 'es',
  });

  final bool notifications;
  final bool sound;
  final bool soundEffects;

  /// Idioma de la app. Por ahora solo español.
  final String languageCode;

  AppPreferences copyWith({
    bool? notifications,
    bool? sound,
    bool? soundEffects,
    String? languageCode,
  }) {
    return AppPreferences(
      notifications: notifications ?? this.notifications,
      sound: sound ?? this.sound,
      soundEffects: soundEffects ?? this.soundEffects,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
