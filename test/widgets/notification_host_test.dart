import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/friends_controller.dart';
import 'package:party_tricks/controllers/invite_controller.dart';
import 'package:party_tricks/controllers/navigation_controller.dart';
import 'package:party_tricks/controllers/preferences_controller.dart';
import 'package:party_tricks/models/app_preferences.dart';
import 'package:party_tricks/models/app_section.dart';
import 'package:party_tricks/models/notification_payload.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/notifications/notification_providers.dart';
import 'package:party_tricks/services/notifications/notification_service.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/widgets/notification_host.dart';

import '../services/preferences/fake_preferences_service.dart';
import '../services/social/fake_social_services.dart';

/// Notificaciones falsas: guarda a quién se le avisa y deja "tocar" una.
class FakeNotificationService implements NotificationService {
  final started = <String>[];
  final stopped = <String>[];
  bool Function(NotificationPayload)? shouldShow;
  final _events = StreamController<NotificationEvent>.broadcast();

  void emit(NotificationPayload payload, NotificationReply reply) =>
      _events.add(NotificationEvent(payload, reply));

  @override
  Stream<NotificationEvent> get events => _events.stream;

  @override
  Future<void> start(
    String uid, {
    required bool Function(NotificationPayload payload) shouldShow,
  }) async {
    started.add(uid);
    this.shouldShow = shouldShow;
  }

  @override
  Future<void> stop(String uid) async => stopped.add(uid);
}

/// El controlador de invitaciones con "Unirse" falso: guarda el código y
/// falla con un mensaje, para no armar toda la sala.
class _FakeInviteController extends InviteController {
  _FakeInviteController(super.ref);

  final accepted = <String>[];

  @override
  Future<Room> accept(String roomCode) async {
    accepted.add(roomCode);
    throw const SocialException('La party ya empezó');
  }
}

const _profile = UserProfile(
  uid: 'beto',
  email: 'beto@x.com',
  username: 'beto',
  friendCode: 'BETO',
);

const _invite = NotificationPayload(
  kind: NotificationKind.invite,
  fromUid: 'ana',
  fromName: 'Ana',
  body: 'Ana te invitó a su party',
  inviteId: 'inv1',
  roomId: 'room1',
  roomCode: 'ABC123',
);

const _message = NotificationPayload(
  kind: NotificationKind.message,
  fromUid: 'ana',
  fromName: 'Ana',
  body: 'Hola',
);

void main() {
  late FakeNotificationService service;
  late FakeInviteService invites;
  late _FakeInviteController inviteController;
  late ProviderContainer container;
  late StreamController<UserProfile?> profile;

  Future<void> pump(
    WidgetTester tester, {
    AppPreferences prefs = const AppPreferences(),
    UserProfile? signedIn = _profile,
  }) async {
    service = FakeNotificationService();
    invites = FakeInviteService();
    profile = StreamController<UserProfile?>.broadcast();
    container = ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(service),
        inviteServiceProvider.overrideWithValue(invites),
        preferencesServiceProvider.overrideWithValue(
          FakePreferencesService(prefs),
        ),
        userProfileProvider.overrideWith((ref) async* {
          if (signedIn != null) yield signedIn;
          yield* profile.stream;
        }),
        inviteControllerProvider.overrideWith((ref) {
          return inviteController = _FakeInviteController(ref);
        }),
      ],
    );
    addTearDown(container.dispose);
    // Sin esperar: el cierre de un stream en vivo no avisa hasta que lo
    // dejen de escuchar.
    addTearDown(() {
      unawaited(profile.close());
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: NotificationHost(child: SizedBox())),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('cuándo avisa', () {
    testWidgets('con la sesión iniciada empieza a avisarle a ese jugador', (
      tester,
    ) async {
      await pump(tester);
      expect(service.started, ['beto']);
    });

    testWidgets('sin sesión no avisa a nadie', (tester) async {
      await pump(tester, signedIn: null);
      expect(service.started, isEmpty);
    });

    testWidgets('con las notificaciones apagadas en Ajustes no avisa', (
      tester,
    ) async {
      await pump(tester, prefs: const AppPreferences(notifications: false));
      expect(service.started, isEmpty);
    });

    testWidgets('al apagar el interruptor deja de avisar', (tester) async {
      await pump(tester);
      await container
          .read(preferencesControllerProvider.notifier)
          .setNotifications(false);
      await tester.pump();
      expect(service.stopped, ['beto']);
    });

    testWidgets('al encender el interruptor vuelve a avisar', (tester) async {
      await pump(tester, prefs: const AppPreferences(notifications: false));
      await container
          .read(preferencesControllerProvider.notifier)
          .setNotifications(true);
      await tester.pump();
      expect(service.started, ['beto']);
    });

    testWidgets('al cerrar sesión deja de avisar', (tester) async {
      await pump(tester);
      profile.add(null);
      await tester.pump();
      await tester.pump();
      expect(service.stopped, ['beto']);
    });
  });

  group('con la app abierta', () {
    testWidgets('un mensaje avisa, salvo si ya tienes ese chat abierto', (
      tester,
    ) async {
      await pump(tester);
      expect(service.shouldShow!(_message), isTrue);
      container.read(openChatProvider.notifier).open('ana');
      expect(service.shouldShow!(_message), isFalse);
    });

    testWidgets('una invitación no avisa: ya sale dentro de la app', (
      tester,
    ) async {
      await pump(tester);
      expect(service.shouldShow!(_invite), isFalse);
    });
  });

  group('lo que se hace con la notificación', () {
    testWidgets('tocar un mensaje abre ese chat en Amigos', (tester) async {
      await pump(tester);
      service.emit(_message, NotificationReply.open);
      await tester.pump();
      expect(container.read(navigationControllerProvider), AppSection.friends);
      expect(container.read(openChatProvider), 'ana');
    });

    testWidgets('tocar una invitación lleva a Amigos sin abrir un chat', (
      tester,
    ) async {
      await pump(tester);
      service.emit(_invite, NotificationReply.open);
      await tester.pump();
      expect(container.read(navigationControllerProvider), AppSection.friends);
      expect(container.read(openChatProvider), isNull);
    });

    testWidgets('Rechazar descarta la invitación', (tester) async {
      await pump(tester);
      service.emit(_invite, NotificationReply.decline);
      await tester.pump();
      expect(invites.declined, ['inv1']);
      expect(inviteController.accepted, isEmpty);
    });

    testWidgets('Aceptar entra a la sala y marca la invitación como vista', (
      tester,
    ) async {
      await pump(tester);
      service.emit(_invite, NotificationReply.accept);
      await tester.pump();
      await tester.pump();
      expect(inviteController.accepted, ['ABC123']);
      expect(invites.seen, ['inv1']);
      expect(invites.declined, isEmpty);
      // Si no se puede entrar, se dice por qué.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('La party ya empezó'), findsOneWidget);
    });
  });
}
