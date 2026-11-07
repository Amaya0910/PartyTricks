import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/admin_controller.dart';
import 'package:party_tricks/controllers/preferences_controller.dart';
import 'package:party_tricks/models/admin/app_overview.dart';
import 'package:party_tricks/models/auth_user.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/screens/admin/admin_screen.dart';
import 'package:party_tricks/screens/admin/admin_stats_screen.dart';
import 'package:party_tricks/screens/admin/minigame_practice_screen.dart';
import 'package:party_tricks/screens/settings_screen.dart';
import 'package:party_tricks/services/admin/admin_providers.dart';
import 'package:party_tricks/services/admin/admin_service.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/widgets/minigames/minigame_result_overlay.dart';

import '../services/admin/fake_admin_service.dart';
import '../services/auth/fake_auth_service.dart';
import '../services/game_engine/fake_random_source.dart';
import '../services/preferences/fake_preferences_service.dart';

const _profile = UserProfile(
  uid: 'me',
  email: 'tay@correo.com',
  username: 'Tay_pro32',
  friendCode: 'ABC234',
);

void main() {
  late FakeAdminService admin;

  setUp(() => admin = FakeAdminService(admins: {'me'}));

  Future<ProviderContainer> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const user = AuthUser(
      uid: 'me',
      email: 'tay@correo.com',
      emailVerified: true,
      providers: {AuthUser.passwordProvider},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
          userProfileProvider.overrideWith((ref) => Stream.value(_profile)),
          authUserProvider.overrideWith((ref) => Stream.value(user)),
          preferencesServiceProvider.overrideWithValue(
            FakePreferencesService(),
          ),
          adminServiceProvider.overrideWithValue(admin),
        ],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byWidget(home)));
  }

  group('Ajustes', () {
    testWidgets('muestra la entrada solo a los administradores', (
      tester,
    ) async {
      await pump(tester, const SettingsScreen());
      expect(find.text('Panel de administración'), findsOneWidget);

      admin = FakeAdminService();
      await pump(tester, const SettingsScreen());
      expect(find.text('Panel de administración'), findsNothing);
    });

    testWidgets('abre el panel', (tester) async {
      await pump(tester, const SettingsScreen());
      await tester.tap(find.text('Panel de administración'));
      await tester.pumpAndSettle();
      expect(find.text('Galería de pantallas'), findsOneWidget);
      expect(find.text('Mi uid'), findsOneWidget);
    });
  });

  group('Economía', () {
    testWidgets('suma monedas, diamantes y dados a la cuenta propia', (
      tester,
    ) async {
      await pump(tester, const AdminScreen());
      await tester.tap(find.text('+100 monedas'));
      await tester.tap(find.text('+10 diamantes'));
      await tester.tap(find.text('+1 dado extra'));
      await tester.pump();
      expect(admin.walletOf('me'), (coins: 100, diamonds: 10, extraDice: 1));
    });

    testWidgets('no deja usarlas a quien no es administrador', (tester) async {
      admin = FakeAdminService();
      final container = await pump(tester, const AdminScreen());
      expect(find.text('Esta cuenta no es administradora.'), findsOneWidget);
      expect(find.text('+100 monedas'), findsNothing);
      expect(
        () => container.read(adminControllerProvider).adjustWallet(coins: 5),
        throwsA(isA<AdminException>()),
      );
      expect(admin.walletOf('me').coins, 0);
    });
  });

  group('Estadísticas', () {
    testWidgets('muestra los números de la app', (tester) async {
      admin.overview = const AppOverview(
        users: 12,
        matches: 30,
        publicMatches: 4,
        secondsInApp: 5400,
      );
      await pump(tester, const AdminStatsScreen());
      expect(find.text('12'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('2,5'), findsOneWidget, reason: '30 / 12');
      expect(find.text('1,5 h'), findsOneWidget);
    });

    testWidgets('avisa si no se pueden leer', (tester) async {
      await pump(tester, const AdminStatsScreen());
      expect(find.text('Sin permiso.'), findsOneWidget);
    });
  });

  group('Práctica de minijuegos', () {
    const rules = MinigameRules();

    testWidgets('se juega contra los rivales de mentira y sale el ganador', (
      tester,
    ) async {
      // Objetivo 7 s; Beto para en 6,70 s y Caro en 7,50 s.
      await tester.pumpWidget(
        MaterialApp(
          home: MinigamePracticeScreen(
            random: FakeRandomSource([7, -300, 500]),
          ),
        ),
      );
      await tester.tap(find.text(MinigameType.stopwatch.title));
      await tester.pump();
      expect(find.text('Empieza en'), findsOneWidget);

      await tester.pump(Duration(milliseconds: rules.introMs + 7000));
      await tester.tap(find.text('¡Ya!'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MinigameResultCard), findsOneWidget);
      expect(find.text('Ganó Tú'), findsOneWidget);

      await tester.pump(MinigameResultOverlay.duration);
    });

    testWidgets('todos se pueden practicar y terminan aunque no toques nada', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1800, 1000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final type in MinigameType.values) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          MaterialApp(
            home: MinigamePracticeScreen(
              random: DartRandomSource(Random(type.index + 1)),
            ),
          ),
        );
        await tester.tap(find.text(type.title));
        await tester.pump();

        var seconds = 0.0;
        while (find.byType(MinigameResultCard).evaluate().isEmpty) {
          await tester.pump(const Duration(milliseconds: 250));
          seconds += 0.25;
          expect(seconds, lessThan(400), reason: '$type no terminó');
        }
        await tester.pump(MinigameResultOverlay.duration);
      }
    });
  });
}
