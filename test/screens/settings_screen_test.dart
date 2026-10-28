import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/preferences_controller.dart';
import 'package:party_tricks/models/auth_user.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/screens/settings_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';

import '../services/auth/fake_auth_service.dart';
import '../services/preferences/fake_preferences_service.dart';

void main() {
  const profile = UserProfile(
    uid: 'me',
    email: 'tay@correo.com',
    username: 'Tay_pro32',
    friendCode: 'ABC234',
  );

  late FakeAuthService auth;
  late FakePreferencesService preferences;
  String? copied;

  setUp(() {
    auth = FakeAuthService();
    preferences = FakePreferencesService();
    copied = null;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Set<String> providers = const {AuthUser.passwordProvider},
    bool verified = true,
  }) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final user = AuthUser(
      uid: 'me',
      email: profile.email,
      emailVerified: verified,
      providers: providers,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          authUserProvider.overrideWith((ref) => Stream.value(user)),
          preferencesServiceProvider.overrideWithValue(preferences),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el código, la cuenta y las preferencias', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Tu código'), findsOneWidget);
    for (final char in 'ABC234'.split('')) {
      expect(find.text(char), findsOneWidget);
    }
    expect(find.text('Tay_pro32'), findsOneWidget);
    expect(find.text('tay@correo.com'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(3));
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('Copiar pone el código en el portapapeles', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Copiar'));
    await tester.pump();

    expect(copied, 'ABC234');
    expect(find.text('Código copiado'), findsOneWidget);
  });

  testWidgets('un interruptor se guarda en el celular', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(preferences.saved.notifications, isFalse);
  });

  testWidgets('las cuentas de Google no cambian la contraseña aquí', (
    tester,
  ) async {
    await pumpScreen(tester, providers: const {AuthUser.googleProvider});

    expect(find.text('Cambiar contraseña'), findsNothing);
  });

  testWidgets('sin verificar el correo sale el aviso', (tester) async {
    await pumpScreen(tester, verified: false);

    expect(find.text('Reenviar'), findsOneWidget);

    await tester.tap(find.text('Reenviar'));
    await tester.pump();

    expect(auth.verificationEmails, 1);
  });

  testWidgets('abre los términos y condiciones', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Términos y condiciones'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Términos y condiciones'),
      ),
      findsOneWidget,
    );
  });
}
