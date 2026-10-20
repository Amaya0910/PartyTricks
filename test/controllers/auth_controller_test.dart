import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/auth/auth_service.dart';

import '../services/auth/fake_auth_service.dart';

void main() {
  late FakeAuthService service;
  late ProviderContainer container;

  setUp(() {
    service = FakeAuthService();
    container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
  });

  Future<bool> register({
    String email = 'tay@correo.com',
    String username = 'tay_01',
    String password = 'Clave123!',
    String confirmPassword = 'Clave123!',
  }) {
    return container
        .read(authControllerProvider.notifier)
        .register(
          email: email,
          username: username,
          password: password,
          confirmPassword: confirmPassword,
        );
  }

  Future<bool> signIn({
    String identifier = 'tay@correo.com',
    String password = 'clave',
  }) {
    return container
        .read(authControllerProvider.notifier)
        .signIn(identifier: identifier, password: password);
  }

  group('register', () {
    test('con datos válidos llama al servicio y no deja error', () async {
      final ok = await register();

      expect(ok, isTrue);
      expect(service.registerCalls, 1);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('con un dato inválido no llama al servicio', () async {
      final ok = await register(username: 'a');

      expect(ok, isFalse);
      expect(service.registerCalls, 0);
      expect(container.read(authControllerProvider).errorMessage, isNotNull);
    });

    test('con una contraseña débil no llama al servicio', () async {
      final ok = await register(password: 'clave1234', confirmPassword: 'clave1234');

      expect(ok, isFalse);
      expect(service.registerCalls, 0);
      expect(
        container.read(authControllerProvider).errorMessage,
        'La contraseña debe incluir una mayúscula.',
      );
    });

    test('si las contraseñas no coinciden muestra el error', () async {
      final ok = await register(confirmPassword: 'Otra123!');

      expect(ok, isFalse);
      expect(service.registerCalls, 0);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Las contraseñas no coinciden.',
      );
    });

    test('muestra el mensaje del servicio si falla', () async {
      service.nextError = const AuthException(
        'Ese nombre de usuario ya está en uso.',
      );

      final ok = await register();

      expect(ok, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Ese nombre de usuario ya está en uso.');
    });

    test('está cargando mientras espera al servicio', () async {
      final gate = Completer<void>();
      service.gate = gate;

      final future = register();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authControllerProvider).isLoading, isTrue);

      gate.complete();
      expect(await future, isTrue);
      expect(container.read(authControllerProvider).isLoading, isFalse);
    });
  });

  group('signIn', () {
    test('con un correo llama al servicio', () async {
      final ok = await signIn(identifier: 'tay@correo.com');

      expect(ok, isTrue);
      expect(service.signInCalls, 1);
      expect(service.lastIdentifier, 'tay@correo.com');
    });

    test('con un nombre de usuario llama al servicio', () async {
      final ok = await signIn(identifier: 'Tay_01');

      expect(ok, isTrue);
      expect(service.signInCalls, 1);
      expect(service.lastIdentifier, 'Tay_01');
    });

    test('con el identificador vacío no llama al servicio', () async {
      final ok = await signIn(identifier: '');

      expect(ok, isFalse);
      expect(service.signInCalls, 0);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Escribe tu correo o nombre de usuario.',
      );
    });

    test('con la contraseña vacía no llama al servicio', () async {
      final ok = await signIn(password: '');

      expect(ok, isFalse);
      expect(service.signInCalls, 0);
    });

    test('muestra el mensaje del servicio si los datos son incorrectos',
        () async {
      service.nextError = const AuthException(
        'Correo, usuario o contraseña incorrectos.',
      );

      final ok = await signIn();

      expect(ok, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        'Correo, usuario o contraseña incorrectos.',
      );
    });
  });

  test('clearError quita el mensaje', () async {
    await register(username: 'a');
    expect(container.read(authControllerProvider).errorMessage, isNotNull);

    container.read(authControllerProvider.notifier).clearError();

    expect(container.read(authControllerProvider).errorMessage, isNull);
  });

  test('signOut llama al servicio', () async {
    await container.read(authControllerProvider.notifier).signOut();

    expect(service.signOutCalls, 1);
  });
}
