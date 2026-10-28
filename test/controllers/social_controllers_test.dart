import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/chat_controller.dart';
import 'package:party_tricks/controllers/friends_controller.dart';
import 'package:party_tricks/controllers/invite_controller.dart';
import 'package:party_tricks/controllers/moderation_controller.dart';
import 'package:party_tricks/controllers/public_profile_controller.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/social/report_reason.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/social/friends_service.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

import '../services/social/fake_social_services.dart';
import '../services/stats/fake_stats_service.dart';

const _me = UserProfile(
  uid: 'me',
  email: 'tay@correo.com',
  username: 'Tay',
  friendCode: 'MYCDE2',
  experience: 120,
);

void main() {
  final now = DateTime(2026, 10, 27, 18);
  late FakeProfileDirectory profiles;
  late FakeFriendsService friends;
  late FakeModerationService moderation;
  late FakeChatService chat;
  late FakeInviteService invites;
  late FakeStatsService stats;

  setUp(() {
    profiles = FakeProfileDirectory();
    friends = FakeFriendsService();
    moderation = FakeModerationService();
    chat = FakeChatService();
    invites = FakeInviteService();
    stats = FakeStatsService();
  });

  /// Contenedor con el jugador "me" y su amiga "ana".
  Future<ProviderContainer> container({
    Set<String> friendUids = const {'ana'},
  }) async {
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith((ref) => Stream.value(_me)),
        currentUidProvider.overrideWithValue('me'),
        friendUidsProvider.overrideWithValue(friendUids),
        profileDirectoryProvider.overrideWithValue(profiles),
        friendsServiceProvider.overrideWithValue(friends),
        moderationServiceProvider.overrideWithValue(moderation),
        chatServiceProvider.overrideWithValue(chat),
        inviteServiceProvider.overrideWithValue(invites),
        statsServiceProvider.overrideWithValue(stats),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    // Riverpod 3 pausa los proveedores que nadie escucha.
    container.listen(userProfileProvider, (_, _) {});
    await container.read(userProfileProvider.future);
    return container;
  }

  group('FriendsController.addByCode', () {
    test('envía la solicitud al dueño del código', () async {
      profiles.codes['ABC234'] = 'beto';
      final c = await container();

      final message = await c
          .read(friendsControllerProvider)
          .addByCode('abc-234');

      expect(message, 'Solicitud enviada.');
      expect(friends.requests, [('me', 'beto')]);
    });

    test('si el otro ya me había enviado una, quedamos como amigos', () async {
      profiles.codes['ABC234'] = 'beto';
      friends.nextResult = FriendRequestResult.accepted;
      final c = await container();

      final message = await c
          .read(friendsControllerProvider)
          .addByCode('ABC234');

      expect(message, '¡Ahora son amigos!');
    });

    Future<String> errorFor(String code) async {
      final c = await container();
      try {
        await c.read(friendsControllerProvider).addByCode(code);
        return 'sin error';
      } on SocialException catch (error) {
        return error.message;
      }
    }

    test('rechaza códigos inválidos', () async {
      expect(await errorFor('ABC'), 'El código no es válido.');
    });

    test('rechaza el propio código', () async {
      expect(await errorFor('myc-de2'), 'Ese es tu propio código.');
      expect(friends.requests, isEmpty);
    });

    test('avisa si el código no existe', () async {
      expect(
        await errorFor('ZZZ999'),
        'No existe un jugador con ese código.',
      );
    });

    test('no envía si el otro me bloqueó, sin decirlo', () async {
      profiles.codes['ABC234'] = 'beto';
      moderation.blocks.add(('beto', 'me'));

      expect(await errorFor('ABC234'), 'No se pudo enviar la solicitud.');
      expect(friends.requests, isEmpty);
    });

    test('no envía si yo lo bloqueé', () async {
      profiles.codes['ABC234'] = 'beto';
      moderation.blocks.add(('me', 'beto'));

      expect(await errorFor('ABC234'), contains('Bloqueaste'));
      expect(friends.requests, isEmpty);
    });
  });

  group('ChatController.send', () {
    test('envía el mensaje limpio y lo suma a las estadísticas', () async {
      final c = await container();

      await c
          .read(chatControllerProvider)
          .send(friendUid: 'ana', text: '  Jugamos?  ');

      final (from, to, message) = chat.sent.single;
      expect(from, 'me');
      expect(to, 'ana');
      expect(message.text, 'Jugamos?');
      expect(message.sentAt, now);
      expect(stats.socialCounters, [('me', SocialCounter.messageSent)]);
    });

    test('no envía mensajes vacíos ni muy largos', () async {
      final c = await container();
      final controller = c.read(chatControllerProvider);

      await expectLater(
        controller.send(friendUid: 'ana', text: '   '),
        throwsA(isA<SocialException>()),
      );
      await expectLater(
        controller.send(
          friendUid: 'ana',
          text: 'a' * (ChatMessage.maxLength + 1),
        ),
        throwsA(isA<SocialException>()),
      );
      expect(chat.sent, isEmpty);
    });

    test('solo se le escribe a amigos', () async {
      final c = await container();

      await expectLater(
        c.read(chatControllerProvider).send(friendUid: 'beto', text: 'hola'),
        throwsA(isA<SocialException>()),
      );
    });

    test('no se le escribe a quien te bloqueó', () async {
      moderation.blocks.add(('ana', 'me'));
      final c = await container();

      await expectLater(
        c.read(chatControllerProvider).send(friendUid: 'ana', text: 'hola'),
        throwsA(isA<SocialException>()),
      );
      expect(chat.sent, isEmpty);
    });

    test('un error de conexión se convierte en un mensaje claro', () async {
      chat.nextError = Exception('unavailable');
      final c = await container();

      await expectLater(
        c.read(chatControllerProvider).send(friendUid: 'ana', text: 'hola'),
        throwsA(
          isA<SocialException>().having(
            (e) => e.message,
            'message',
            contains('Revisa tu conexión'),
          ),
        ),
      );
    });

    test('markRead marca el chat de la pareja', () async {
      final c = await container();

      await c.read(chatControllerProvider).markRead('ana');

      expect(chat.reads, [('ana_me', 'me')]);
    });
  });

  group('InviteController.invite', () {
    final room = Room(
      id: 'sala1',
      code: 'ABC234',
      isPublic: false,
      hostUid: 'me',
      maxPlayers: 4,
      rounds: 10,
      status: RoomStatus.waiting,
      lobbyEndsAt: DateTime(2026, 10, 27, 18, 2),
    );

    test('invita solo a amigos que no me bloquearon', () async {
      moderation.blocks.add(('caro', 'me'));
      final c = await container(friendUids: {'ana', 'caro'});

      final sent = await c
          .read(inviteControllerProvider)
          .invite(room: room, friendUids: ['ana', 'caro', 'desconocido']);

      expect(sent, 1);
      final invite = invites.sent.single;
      expect(invite.fromUid, 'me');
      expect(invite.fromName, 'Tay');
      expect(invite.toUid, 'ana');
      expect(invite.roomId, 'sala1');
      expect(invite.roomCode, 'ABC234');
      expect(stats.socialCounters, [('me', SocialCounter.inviteSent)]);
    });
  });

  group('ModerationController', () {
    test('bloquear y reportar', () async {
      final c = await container();
      final controller = c.read(moderationControllerProvider);

      await controller.block('ana');
      await controller.report('ana', ReportReason.harassment);

      expect(moderation.blocks, contains(('me', 'ana')));
      expect(moderation.reports, [('me', 'ana', ReportReason.harassment)]);
    });

    test('desbloquear', () async {
      moderation.blocks.add(('me', 'ana'));
      final c = await container();

      await c.read(moderationControllerProvider).unblock('ana');

      expect(moderation.blocks, isEmpty);
    });
  });

  group('PublicProfileController', () {
    test('publica sin el correo y solo cuando algo cambia', () async {
      final c = await container();
      final controller = c.read(publicProfileControllerProvider);

      await controller.sync(_me);
      await controller.sync(_me);

      expect(profiles.published, hasLength(1));
      final published = profiles.published.single;
      expect(published.username, 'Tay');
      expect(published.friendCode, 'MYCDE2');
      expect(published.experience, 120);
      expect(published.toMap().containsKey('email'), isFalse);

      await controller.sync(_me.copyWith(experience: 200));
      expect(profiles.published, hasLength(2));
    });
  });
}
