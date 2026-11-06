import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/avatar_color.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/widgets/character/head_avatar.dart';
import 'package:party_tricks/widgets/chest_reward_dialog.dart';
import 'package:party_tricks/widgets/profile_avatar.dart';

void main() {
  test('el perfil público guarda y lee cómo se ve la cabeza', () {
    const profile = PublicProfile(
      uid: 'u',
      username: 'Ana',
      skinTone: 25,
      eyes: EyeStyle.ojo3,
      eyeColor: 4,
      mouth: MouthStyle.boca5,
      mouthColor: 6,
      avatarColor: 9,
    );
    final read = PublicProfile.fromMap('u', profile.toMap());
    expect(read.sameAs(profile), isTrue);
    expect(read.skinTone, 25);
    expect(read.eyes, EyeStyle.ojo3);
    expect(read.mouth, MouthStyle.boca5);
    expect(read.avatarColor, 9);
  });

  test('un perfil público viejo, sin esos campos, usa los de inicio', () {
    final read = PublicProfile.fromMap('u', {'username': 'Ana'});
    expect(read.eyes, EyeStyle.defaultStyle);
    expect(read.mouth, MouthStyle.defaultStyle);
    expect(read.avatarColor, AvatarColor.defaultIndex);
  });

  test('el color de fondo de la foto se guarda en el perfil', () {
    const profile = UserProfile(
      uid: 'u',
      email: 'a@b.co',
      username: 'abc',
      friendCode: 'XYZ789',
      avatarColor: 5,
    );
    expect(UserProfile.fromMap('u', profile.toMap()).avatarColor, 5);
    expect(
      UserProfile.fromMap('u', {'avatarColor': 999}).avatarColor,
      AvatarColor.count - 1,
    );
  });

  testWidgets('ProfileAvatar dibuja la cabeza con su color de fondo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileAvatar(
            profile: PublicProfile(uid: 'u', username: 'Ana', avatarColor: 3),
          ),
        ),
      ),
    );
    expect(find.byType(HeadAvatar), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets('ProfileAvatar sin perfil muestra un ícono', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileAvatar())),
    );
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  Future<void> showReward(WidgetTester tester, ChestPrize prize) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                uid: 'u',
                email: 'a@b.co',
                username: 'abc',
                friendCode: 'XYZ789',
                coins: 250,
                extraDice: 2,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChestRewardDialog(chest: ChestType.party, prize: prize),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('la ventana de premio muestra las monedas ganadas', (
    tester,
  ) async {
    await showReward(tester, const ChestPrize(ChestOutcome.coins));
    expect(find.text('¡Monedas!'), findsOneWidget);
    expect(find.text('+$chestCoinPrize monedas'), findsOneWidget);
    expect(find.text('Ahora tienes 250 monedas'), findsOneWidget);
  });

  testWidgets('la ventana de premio muestra el dado extra', (tester) async {
    await showReward(tester, const ChestPrize(ChestOutcome.dice));
    expect(find.text('¡Dado extra!'), findsOneWidget);
    expect(find.text('+1 dado extra'), findsOneWidget);
    expect(find.text('Ahora tienes 2 dados extra'), findsOneWidget);
  });

  testWidgets('la ventana de premio muestra el cosmético y su rareza', (
    tester,
  ) async {
    await showReward(
      tester,
      const ChestPrize(ChestOutcome.cosmetic, eyes: EyeStyle.ojo11),
    );
    expect(find.text('¡Cosmético nuevo!'), findsOneWidget);
    expect(find.text(EyeStyle.ojo11.title), findsOneWidget);
    expect(find.text('Legendario'), findsOneWidget);
  });

  testWidgets('la ventana de premio avisa si el cofre salió vacío', (
    tester,
  ) async {
    await showReward(tester, const ChestPrize(ChestOutcome.nothing));
    expect(find.text('Cofre vacío'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
  });
}
