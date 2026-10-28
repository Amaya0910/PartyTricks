import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/preferences_controller.dart';
import 'package:party_tricks/models/app_preferences.dart';

import '../services/preferences/fake_preferences_service.dart';

void main() {
  late FakePreferencesService service;
  late ProviderContainer container;

  Future<void> start([AppPreferences saved = const AppPreferences()]) async {
    service = FakePreferencesService(saved);
    container = ProviderContainer(
      overrides: [preferencesServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    container.listen(preferencesControllerProvider, (_, _) {});
    await container.read(preferencesControllerProvider.future);
  }

  AppPreferences current() =>
      container.read(preferencesControllerProvider).requireValue;

  PreferencesController notifier() =>
      container.read(preferencesControllerProvider.notifier);

  test('carga lo guardado en el celular', () async {
    await start(const AppPreferences(sound: false));

    expect(current().sound, isFalse);
    expect(current().notifications, isTrue);
  });

  test('cada interruptor cambia solo su valor y se guarda', () async {
    await start();

    await notifier().setNotifications(false);
    await notifier().setSoundEffects(false);

    expect(current().notifications, isFalse);
    expect(current().sound, isTrue);
    expect(current().soundEffects, isFalse);
    expect(service.saved.soundEffects, isFalse);
    expect(service.saveCalls, 2);
  });

  test('setSound guarda el sonido', () async {
    await start();

    await notifier().setSound(false);

    expect(service.saved.sound, isFalse);
  });
}
