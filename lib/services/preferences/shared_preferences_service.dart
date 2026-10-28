import 'package:party_tricks/models/app_preferences.dart';
import 'package:party_tricks/services/preferences/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias con `shared_preferences` (se quedan en el celular, no en
/// Firebase).
class SharedPreferencesService implements PreferencesService {
  SharedPreferencesService([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _notifications = 'prefs.notifications';
  static const _sound = 'prefs.sound';
  static const _soundEffects = 'prefs.soundEffects';
  static const _language = 'prefs.language';

  @override
  Future<AppPreferences> load() async {
    const defaults = AppPreferences();
    return AppPreferences(
      notifications:
          await _prefs.getBool(_notifications) ?? defaults.notifications,
      sound: await _prefs.getBool(_sound) ?? defaults.sound,
      soundEffects:
          await _prefs.getBool(_soundEffects) ?? defaults.soundEffects,
      languageCode: await _prefs.getString(_language) ?? defaults.languageCode,
    );
  }

  @override
  Future<void> save(AppPreferences preferences) async {
    await _prefs.setBool(_notifications, preferences.notifications);
    await _prefs.setBool(_sound, preferences.sound);
    await _prefs.setBool(_soundEffects, preferences.soundEffects);
    await _prefs.setString(_language, preferences.languageCode);
  }
}
