import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/navigation_controller.dart';
import 'package:party_tricks/models/app_section.dart';
import 'package:party_tricks/models/social/friendship.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/screens/friends_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/social/social_providers.dart';

import '../services/social/fake_social_services.dart';

void main() {
  const me = UserProfile(
    uid: 'me',
    email: 'tay@correo.com',
    username: 'Tay',
    friendCode: 'ABC234',
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    List<Friendship> friendships,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(me)),
          currentUidProvider.overrideWithValue('me'),
          friendshipsProvider.overrideWith((ref) => Stream.value(friendships)),
          chatsProvider.overrideWith((ref) => Stream.value(const {})),
          profileDirectoryProvider.overrideWithValue(FakeProfileDirectory()),
          chatServiceProvider.overrideWithValue(FakeChatService()),
        ],
        child: const MaterialApp(home: Scaffold(body: FriendsScreen())),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('sin amigos muestra el título, el código y cómo agregar', (
    tester,
  ) async {
    await pumpScreen(tester, const []);

    expect(find.text('Tus amigos'), findsOneWidget);
    expect(find.text('Tu código: ABC-234'), findsOneWidget);
    expect(find.textContaining('Aún no tienes amigos'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('muestra las solicitudes recibidas con Aceptar y Rechazar', (
    tester,
  ) async {
    await pumpScreen(tester, [
      friendshipOf(
        'me',
        'ana',
        status: FriendshipStatus.pending,
        requestedBy: 'ana',
      ),
    ]);

    expect(find.text('Solicitudes (1)'), findsOneWidget);
    expect(find.text('Quiere ser tu amigo'), findsOneWidget);
    expect(find.byTooltip('Aceptar'), findsOneWidget);
    expect(find.byTooltip('Rechazar'), findsOneWidget);
  });

  testWidgets('al tocar un amigo se abre el chat en la misma pestaña', (
    tester,
  ) async {
    await pumpScreen(tester, [friendshipOf('me', 'ana')]);

    await tester.tap(find.text('¡Escríbele!'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Presiona para escribir'), findsOneWidget);
    expect(find.text('Tus amigos'), findsNothing);
  });

  testWidgets('la flecha del chat vuelve a la lista', (tester) async {
    await pumpScreen(tester, [friendshipOf('me', 'ana')]);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FriendsScreen)),
    );
    container.read(navigationControllerProvider.notifier).select(
      AppSection.friends,
    );

    await tester.tap(find.text('¡Escríbele!'));
    await tester.pump();
    await tester.tap(find.byTooltip('Volver'));
    await tester.pump();

    expect(find.text('Tus amigos'), findsOneWidget);
  });
}
