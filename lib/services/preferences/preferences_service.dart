import 'package:party_tricks/models/app_preferences.dart';

/// Guarda las preferencias en el celular. La versión real usa
/// `shared_preferences`; en las pruebas se puede cambiar por una falsa.
abstract class PreferencesService {
  Future<AppPreferences> load();

  Future<void> save(AppPreferences preferences);
}
