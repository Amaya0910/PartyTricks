import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/screens/auth_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/auth/auth_service.dart';

import '../services/auth/fake_auth_service.dart';

void main() {
  late FakeAuthService service;

  setUp(() => service = FakeAuthService());

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
  }

  Finder field(int index) => find.byType(TextField).at(index);

  testWidgets('empieza en el inicio de sesión', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Inicio de sesion'), findsOneWidget);
    expect(find.text('¿Aun no te registras?'), findsOneWidget);
    expect(find.text('Registrarse'), findsNothing);
  });

  testWidgets('"¿Aun no te registras?" da la vuelta al registro',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('¿Aun no te registras?'));
    await tester.pumpAndSettle();

    expect(find.text('Registrarse'), findsOneWidget);
    expect(find.text('¿Ya tienes una cuenta?'), findsOneWidget);
    expect(find.text('Inicio de sesion'), findsNothing);
  });

  testWidgets('"¿Ya tienes una cuenta?" vuelve al inicio de sesión',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('¿Aun no te registras?'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿Ya tienes una cuenta?'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio de sesion'), findsOneWidget);
    expect(find.text('Registrarse'), findsNothing);
  });

  testWidgets('iniciar sesión con el correo llama al servicio',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(field(0), 'tay@correo.com');
    await tester.enterText(field(1), 'clave');
    await tester.tap(find.text('Entrar a la party'));
    await tester.pumpAndSettle();

    expect(service.signInCalls, 1);
    expect(service.lastIdentifier, 'tay@correo.com');
  });

  testWidgets('iniciar sesión con el nombre de usuario llama al servicio',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(field(0), 'Tay_01');
    await tester.enterText(field(1), 'clave');
    await tester.tap(find.text('Entrar a la party'));
    await tester.pumpAndSettle();

    expect(service.signInCalls, 1);
    expect(service.lastIdentifier, 'Tay_01');
  });

  testWidgets('con los campos vacíos muestra el error y no llama al servicio',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Entrar a la party'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu correo o nombre de usuario.'), findsOneWidget);
    expect(service.signInCalls, 0);
  });

  testWidgets('muestra el mensaje del servicio si el inicio falla',
      (tester) async {
    service.nextError = const AuthException(
      'Correo, usuario o contraseña incorrectos.',
    );
    await pumpScreen(tester);

    await tester.enterText(field(0), 'tay@correo.com');
    await tester.enterText(field(1), 'mala-clave');
    await tester.tap(find.text('Entrar a la party'));
    await tester.pumpAndSettle();

    expect(
      find.text('Correo, usuario o contraseña incorrectos.'),
      findsOneWidget,
    );
  });

  testWidgets('registrarse con datos válidos llama al servicio',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('¿Aun no te registras?'));
    await tester.pumpAndSettle();

    await tester.enterText(field(0), 'tay_01');
    await tester.enterText(field(1), 'tay@correo.com');
    await tester.enterText(field(2), 'Clave123!');
    await tester.enterText(field(3), 'Clave123!');
    await tester.tap(find.text('Entrar a la party'));
    await tester.pumpAndSettle();

    expect(service.registerCalls, 1);
  });

  testWidgets('registrarse con una contraseña débil muestra el error',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('¿Aun no te registras?'));
    await tester.pumpAndSettle();

    await tester.enterText(field(0), 'tay_01');
    await tester.enterText(field(1), 'tay@correo.com');
    await tester.enterText(field(2), 'clave1234');
    await tester.enterText(field(3), 'clave1234');
    await tester.tap(find.text('Entrar a la party'));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña debe incluir una mayúscula.'), findsOneWidget);
    expect(service.registerCalls, 0);
  });

  testWidgets('al voltear se quita el error de la otra cara', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Entrar a la party'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu correo o nombre de usuario.'), findsOneWidget);

    await tester.tap(find.text('¿Aun no te registras?'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu correo o nombre de usuario.'), findsNothing);
  });
}
