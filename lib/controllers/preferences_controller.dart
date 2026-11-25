import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/app_preferences.dart';
import 'package:party_tricks/services/feedback/haptics.dart';
import 'package:party_tricks/services/preferences/preferences_service.dart';
import 'package:party_tricks/services/preferences/shared_preferences_service.dart';

final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => SharedPreferencesService(),
);

/// Preferencias de Ajustes. Cada cambio se ve de una vez y se guarda en el
/// celular.
class PreferencesController extends AsyncNotifier<AppPreferences> {
  @override
  Future<AppPreferences> build() => ref.read(preferencesServiceProvider).load();

  Future<void> setNotifications(bool value) =>
      _update((p) => p.copyWith(notifications: value));

  Future<void> setSound(bool value) => _update((p) => p.copyWith(sound: value));

  Future<void> setSoundEffects(bool value) =>
      _update((p) => p.copyWith(soundEffects: value));

  Future<void> setVibration(bool value) =>
      _update((p) => p.copyWith(vibration: value));

  Future<void> _update(AppPreferences Function(AppPreferences) change) async {
    final current = state.value ?? const AppPreferences();
    final next = change(current);
    state = AsyncData(next);
    await ref.read(preferencesServiceProvider).save(next);
  }
}

final preferencesControllerProvider =
    AsyncNotifierProvider<PreferencesController, AppPreferences>(
      PreferencesController.new,
    );

/// Cómo vibra la app según Ajustes (mientras cargan las preferencias, vibra).
final hapticsProvider = Provider<Haptics>((ref) {
  final on = ref.watch(preferencesControllerProvider).value?.vibration ?? true;
  return on ? const DeviceHaptics() : const SilentHaptics();
});
