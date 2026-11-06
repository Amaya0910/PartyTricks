import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/shop/cosmetic_picker.dart';
import 'package:party_tricks/widgets/chest_dialog.dart';
import 'package:party_tricks/widgets/cosmetic_odds_dialog.dart';

void main() {
  const picker = CosmeticPicker();

  test('las probabilidades suman 100 y siguen el peso de la rareza', () {
    final chances = picker.chances(ownedEyes: {}, ownedMouths: {});
    expect(chances, hasLength(8 + 8 - 0));
    final total = chances.fold<double>(0, (s, c) => s + c.percent);
    expect(total, closeTo(100, 0.0001));

    double of(EyeStyle eyes) =>
        chances.firstWhere((c) => c.eyes == eyes).percent;
    // Común (ojo 1) pesa 50 y legendario (ojo 11), 2.
    expect(of(EyeStyle.ojo1) / of(EyeStyle.ojo11), closeTo(25, 0.0001));
  });

  test('lo que ya tiene no cuenta y el resto se reparte entre los demás', () {
    final all = picker.chances(ownedEyes: {}, ownedMouths: {});
    final fewer = picker.chances(ownedEyes: {1}, ownedMouths: {});
    expect(fewer.any((c) => c.eyes == EyeStyle.ojo1), isFalse);
    expect(fewer, hasLength(all.length - 1));
    expect(
      fewer.fold<double>(0, (s, c) => s + c.percent),
      closeTo(100, 0.0001),
    );
  });

  test('si ya los tiene todos, no queda ninguno', () {
    final chances = picker.chances(
      ownedEyes: {for (final e in EyeStyle.values) e.number},
      ownedMouths: {for (final m in MouthStyle.values) m.number},
    );
    expect(chances, isEmpty);
  });

  Future<void> pump(
    WidgetTester tester,
    Widget home,
    UserProfile profile,
  ) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        ],
        child: MaterialApp(home: Scaffold(body: home)),
      ),
    );
    await tester.pump();
  }

  const profile = UserProfile(
    uid: 'u',
    email: 'a@b.co',
    username: 'abc',
    friendCode: 'XYZ789',
    ownedEyes: {3},
  );

  testWidgets('la ventana lista los cosméticos con su porcentaje', (
    tester,
  ) async {
    await pump(
      tester,
      const CosmeticOddsDialog(chest: ChestType.party),
      profile,
    );
    expect(find.text('Legendario'), findsOneWidget);
    expect(find.text(EyeStyle.ojo11.title), findsOneWidget);
    // Los ojos 3 ya son del jugador: no salen.
    expect(find.text(EyeStyle.ojo3.title), findsNothing);
    expect(find.textContaining('40%'), findsOneWidget);
  });

  testWidgets('en el cofre, tocar "Cosmético aleatorio" abre la ventana', (
    tester,
  ) async {
    await pump(tester, const ChestDialog(chest: ChestType.basic), profile);
    await tester.tap(find.text('Cosmético aleatorio:'));
    await tester.pumpAndSettle();
    expect(find.byType(CosmeticOddsDialog), findsOneWidget);
  });
}
