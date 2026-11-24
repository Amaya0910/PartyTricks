import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/player_slot.dart';

/// El lobby dibuja a cada jugador con su personaje real (no con el muñeco
/// provisional de antes).
void main() {
  final player = RoomPlayer(
    uid: 'ana',
    username: 'Ana',
    joinedAt: DateTime(2026),
  );

  Future<void> pump(WidgetTester tester, Widget slot, {PublicProfile? ana}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicProfileProvider('ana').overrideWith((ref) => Stream.value(ana)),
        ],
        child: MaterialApp(
          home: Center(child: SizedBox(width: 100, height: 140, child: slot)),
        ),
      ),
    );
  }

  testWidgets('un espacio libre no dibuja personaje', (tester) async {
    await pump(tester, const PlayerSlot());
    expect(find.byType(AnimatedCharacter), findsNothing);
  });

  testWidgets('dibuja al jugador con el aspecto de su perfil público', (
    tester,
  ) async {
    const ana = PublicProfile(uid: 'ana', username: 'Ana');
    await pump(tester, PlayerSlot(player: player), ana: ana);
    await tester.pump();
    final character = tester.widget<AnimatedCharacter>(
      find.byType(AnimatedCharacter),
    );
    expect(character.skinTone, ana.look.skinTone);
    expect(character.shirt, ana.shirt);
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('el anfitrión lleva estrella y yo me veo como (tú)', (
    tester,
  ) async {
    await pump(tester, PlayerSlot(player: player, isMe: true, isHost: true));
    await tester.pump();
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.text('Ana(tú)'), findsOneWidget);
  });
}
