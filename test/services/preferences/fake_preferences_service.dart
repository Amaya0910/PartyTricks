import 'package:party_tricks/models/app_preferences.dart';
import 'package:party_tricks/services/preferences/preferences_service.dart';

/// Preferencias en memoria para las pruebas.
class FakePreferencesService implements PreferencesService {
  FakePreferencesService([this.saved = const AppPreferences()]);

  AppPreferences saved;
  int saveCalls = 0;

  @override
  Future<AppPreferences> load() async => saved;

  @override
  Future<void> save(AppPreferences preferences) async {
    saveCalls++;
    saved = preferences;
  }
}
