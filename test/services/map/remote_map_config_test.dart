import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_config_service.dart';
import 'package:party_tricks/services/map/map_providers.dart';
import 'package:party_tricks/services/map/remote_map_config.dart';

import 'fake_maps.dart';

/// Un [MapConfigService] que emite lo que la prueba le diga.
class FakeMapConfigService implements MapConfigService {
  final controller = StreamController<RemoteMapConfig>.broadcast();

  @override
  Stream<RemoteMapConfig> watch() => controller.stream;
}

void main() {
  final dulces = enabled(MapCatalog.mapaDulces);
  final ready = [MapCatalog.mapa01, dulces];

  group('RemoteMapConfig.fromValue', () {
    test('mapa habilitado', () {
      final config = RemoteMapConfig.fromValue({
        'mapa_dulces': {'enabled': true},
      });

      expect(config.isEnabled('mapa_dulces'), isTrue);
      expect(config.availableOf(ready), ready);
    });

    test('mapa deshabilitado', () {
      final config = RemoteMapConfig.fromValue({
        'mapa_dulces': {'enabled': false},
      });

      expect(config.isEnabled('mapa_dulces'), isFalse);
      expect(config.availableOf(ready), [MapCatalog.mapa01]);
    });

    test('configuración vacía o inexistente: solo mapa_01', () {
      for (final value in [null, <String, Object?>{}]) {
        final config = RemoteMapConfig.fromValue(value);
        expect(config, RemoteMapConfig.unavailable, reason: '$value');
        expect(config.availableOf(ready), [MapCatalog.mapa01]);
      }
    });

    test('lo que no tiene la forma esperada cuenta como apagado', () {
      final config = RemoteMapConfig.fromValue({
        'mapa_dulces': true,
        'mapa_b': {'enabled': 'true'},
        'mapa_c': {'enabled': 1},
        'mapa_d': {},
      });

      expect(config.enabledIds, isEmpty);
      expect(RemoteMapConfig.fromValue('basura'), RemoteMapConfig.unavailable);
      expect(RemoteMapConfig.fromValue([true]), RemoteMapConfig.unavailable);
    });

    test('un mapa desconocido se ignora sin romper nada', () {
      final config = RemoteMapConfig.fromValue({
        'mapa_del_futuro': {'enabled': true},
        'mapa_dulces': {'enabled': true},
      });

      expect(config.isEnabled('mapa_del_futuro'), isTrue);
      // Esta versión no lo tiene, así que no aparece.
      expect(config.availableOf(ready), ready);
      // El de Mundo Dulce sí está en el catálogo y está encendido.
      expect(config.availableOf(MapCatalog.all), [
        MapCatalog.mapa01,
        MapCatalog.mapaDulces,
      ]);
    });
  });

  group('las dos condiciones', () {
    test('selectable: false no se muestra aunque esté encendido', () {
      const config = RemoteMapConfig(enabledIds: {'mapa_oculto'});

      expect(hiddenMap.selectable, isFalse);
      expect(config.isAvailable(hiddenMap), isFalse);
      expect(config.isAvailable(enabled(hiddenMap)), isTrue);
    });

    test('un mapa listo no se muestra mientras Firebase no lo encienda', () {
      const config = RemoteMapConfig();

      expect(MapCatalog.mapaDulces.selectable, isTrue);
      expect(config.isAvailable(MapCatalog.mapaDulces), isFalse);
      expect(
        const RemoteMapConfig(
          enabledIds: {'mapa_dulces'},
        ).isAvailable(MapCatalog.mapaDulces),
        isTrue,
      );
    });

    test('mapa_01 siempre está encendido', () {
      const off = RemoteMapConfig();
      expect(off.isEnabled('mapa_01'), isTrue);
      expect(off.isAvailable(MapCatalog.defaultMap), isTrue);
      expect(off.availableOf(MapCatalog.all), [MapCatalog.mapa01]);
    });

    test('un mapa listo pero oculto en el código sigue oculto', () {
      final config = allEnabled([hiddenMap]);
      expect(config.availableOf([hiddenMap, MapCatalog.mapa01]), [
        MapCatalog.mapa01,
      ]);
    });
  });

  group('withFallback', () {
    test('pasa la configuración tal cual', () async {
      const on = RemoteMapConfig(enabledIds: {'mapa_dulces'});
      expect(await withFallback(Stream.value(on)).first, on);
    });

    test('Firebase caído (error): emite unavailable', () async {
      final stream = withFallback(
        Stream<RemoteMapConfig>.error(Exception('permission-denied')),
      );
      expect(await stream.first, RemoteMapConfig.unavailable);
    });

    test('Firebase no responde: unavailable y luego lo que llegue', () async {
      final source = StreamController<RemoteMapConfig>();
      addTearDown(source.close);
      final values = <RemoteMapConfig>[];
      final sub = withFallback(
        source.stream,
        timeout: const Duration(milliseconds: 10),
      ).listen(values.add);
      addTearDown(sub.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(values, [RemoteMapConfig.unavailable]);

      const on = RemoteMapConfig(enabledIds: {'mapa_dulces'});
      source.add(on);
      await Future<void>.delayed(Duration.zero);
      expect(values, [RemoteMapConfig.unavailable, on]);
    });
  });

  group('remoteMapConfigProvider', () {
    const me = UserProfile(
      uid: 'me',
      email: 'tay@correo.com',
      username: 'Tay',
      friendCode: 'MYCDE2',
    );

    ProviderContainer containerWith(
      MapConfigService service, {
      UserProfile? profile = me,
    }) {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          mapConfigServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<RemoteMapConfig> settle(ProviderContainer container) async {
      final sub = container.listen(remoteMapConfigProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(userProfileProvider.future);
      return container.read(remoteMapConfigProvider.future);
    }

    test('sigue los cambios de Firebase en vivo', () async {
      final service = FakeMapConfigService();
      final container = containerWith(service);
      final sub = container.listen(remoteMapConfigProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(userProfileProvider.future);
      await Future<void>.delayed(Duration.zero);

      service.controller.add(
        const RemoteMapConfig(enabledIds: {'mapa_dulces'}),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(remoteMapConfigProvider).value?.isEnabled('mapa_dulces'),
        isTrue,
      );

      // Rollback: se apaga sin publicar nada.
      service.controller.add(RemoteMapConfig.unavailable);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(remoteMapConfigProvider).value?.isEnabled('mapa_dulces'),
        isFalse,
      );
    });

    test('Firebase caído: unavailable, sin error', () async {
      final service = FakeMapConfigService();
      final container = containerWith(service);
      final result = settle(container);
      await Future<void>.delayed(Duration.zero);
      service.controller.addError(Exception('sin conexión'));

      expect(await result, RemoteMapConfig.unavailable);
      expect(container.read(remoteMapConfigProvider).hasError, isFalse);
    });

    test('sin sesión no lee Firebase', () async {
      final service = FakeMapConfigService();
      final container = containerWith(service, profile: null);

      expect(await settle(container), RemoteMapConfig.unavailable);
      expect(service.controller.hasListener, isFalse);
    });
  });
}
