import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/match_stats.dart';
import 'package:party_tricks/models/stats/minigame_stats.dart';
import 'package:party_tricks/models/stats/time_stats.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/screens/stats_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

void main() {
  const profile = UserProfile(
    uid: 'uid-1',
    email: 'tay@correo.com',
    username: 'Tay_pro32',
    friendCode: 'ABC234',
    coins: 999,
    diamonds: 999,
  );

  // Los números del mockup.
  const stats = PlayerStats(
    matches: MatchStats(won: 5, lost: 5, maxDiamonds: 3, maxCoins: 25),
    minigames: MinigameStats(
      won: 30,
      lost: 20,
      maxWonInMatch: 6,
      bestScore: 10,
    ),
    time: TimeStats(
      secondsInApp: 12000,
      secondsPlaying: 10800,
      secondsInMinigames: 7800,
      currentStreak: 6,
      maxStreak: 10,
    ),
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          playerStatsProvider.overrideWith((ref) => Stream.value(stats)),
        ],
        child: const MaterialApp(home: Scaffold(body: StatsScreen())),
      ),
    );
    // Deja llegar el perfil y las estadísticas (no se usa pumpAndSettle
    // porque el indicador de carga se anima sin parar).
    await tester.pump();
    await tester.pump();
  }

  testWidgets('empieza con las tres tarjetas del mockup', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Partidas'), findsOneWidget);
    expect(find.text('Minijuegos'), findsOneWidget);
    expect(find.text('Tiempo'), findsOneWidget);
  });

  testWidgets('muestra los valores con su formato', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Tay_pro32'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('200m'), findsOneWidget);
    expect(find.text('180m'), findsOneWidget);
    expect(find.text('130m'), findsOneWidget);
    expect(find.text('6d'), findsOneWidget);
    expect(find.text('10d'), findsOneWidget);
  });

  testWidgets('al bajar aparecen las tarjetas nuevas', (tester) async {
    await pumpScreen(tester);

    await tester.scrollUntilVisible(
      find.text('Social'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Social'), findsOneWidget);
  });
}
