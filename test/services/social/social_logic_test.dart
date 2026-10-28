import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/social/chat_summary.dart';
import 'package:party_tricks/models/social/friendship.dart';
import 'package:party_tricks/services/social/chat_format.dart';
import 'package:party_tricks/services/social/chat_rules.dart';
import 'package:party_tricks/services/social/friends_sections.dart';
import 'package:party_tricks/services/social/invite_status.dart';
import 'package:party_tricks/services/social/pair_id.dart';

import 'fake_social_services.dart';

void main() {
  group('PairId', () {
    test('es el mismo sin importar el orden', () {
      expect(PairId.of('b', 'a'), 'a_b');
      expect(PairId.of('a', 'b'), 'a_b');
      expect(PairId.members('z', 'm'), ['m', 'z']);
    });
  });

  group('ChatRules', () {
    test('un mensaje vacío o solo con espacios no se envía', () {
      expect(ChatRules.messageError('   '), isNotNull);
      expect(ChatRules.cleanMessage('  '), isNull);
    });

    test('quita los espacios de los extremos', () {
      expect(ChatRules.cleanMessage('  hola  '), 'hola');
      expect(ChatRules.messageError('hola'), isNull);
    });

    test('no deja pasar de 200 caracteres', () {
      expect(ChatRules.messageError('a' * ChatMessage.maxLength), isNull);
      expect(
        ChatRules.messageError('a' * (ChatMessage.maxLength + 1)),
        isNotNull,
      );
    });

    test('el código de amistad acepta guion, espacios y minúsculas', () {
      expect(ChatRules.normalizeFriendCode('abc-234'), 'ABC234');
      expect(ChatRules.friendCodeError('abc 234'), isNull);
    });

    test('rechaza códigos cortos o con letras que se confunden', () {
      expect(ChatRules.friendCodeError('ABC23'), isNotNull);
      expect(ChatRules.friendCodeError('ABC0I1'), isNotNull);
    });
  });

  group('FriendsSections', () {
    final old = DateTime(2026, 10, 1);
    final recent = DateTime(2026, 10, 27);

    test('separa recibidas, amigos y enviadas', () {
      final sections = FriendsSections.build(
        myUid: 'me',
        all: [
          friendshipOf('me', 'ana'),
          friendshipOf(
            'me',
            'beto',
            status: FriendshipStatus.pending,
            requestedBy: 'beto',
          ),
          friendshipOf(
            'me',
            'caro',
            status: FriendshipStatus.pending,
            requestedBy: 'me',
          ),
        ],
      );

      expect([for (final f in sections.incoming) f.otherOf('me')], ['beto']);
      expect([for (final f in sections.friends) f.otherOf('me')], ['ana']);
      expect([for (final f in sections.outgoing) f.otherOf('me')], ['caro']);
      expect(sections.isEmpty, isFalse);
    });

    test('ordena a los amigos por el último mensaje', () {
      final ana = friendshipOf('me', 'ana', createdAt: old);
      final beto = friendshipOf('me', 'beto', createdAt: old);
      final sections = FriendsSections.build(
        myUid: 'me',
        all: [ana, beto],
        chats: {
          beto.id: ChatSummary(
            id: beto.id,
            members: beto.members,
            lastMessage: ChatMessage(
              id: '',
              senderId: 'beto',
              text: 'Hola',
              sentAt: recent,
            ),
          ),
        },
      );

      expect([for (final f in sections.friends) f.otherOf('me')], [
        'beto',
        'ana',
      ]);
    });

    test('sin amistades, está vacío', () {
      expect(FriendsSections.build(myUid: 'me', all: []).isEmpty, isTrue);
    });
  });

  group('ChatFormat', () {
    final now = DateTime(2026, 10, 27, 20);

    test('la hora de hoy va sola; la de otro día lleva la fecha', () {
      expect(ChatFormat.time(DateTime(2026, 10, 27, 9, 5), now), '09:05');
      expect(
        ChatFormat.time(DateTime(2026, 10, 3, 14, 30), now),
        '03/10 14:30',
      );
    });

    test('la vista previa marca mis mensajes y las invitaciones', () {
      final mine = ChatMessage(
        id: '',
        senderId: 'me',
        text: 'Jugamos?',
        sentAt: now,
      );
      final invite = ChatMessage(
        id: '',
        senderId: 'ana',
        text: 'x',
        sentAt: now,
        type: MessageType.invite,
      );

      expect(ChatFormat.preview(mine, 'me'), 'Tú: Jugamos?');
      expect(ChatFormat.preview(invite, 'me'), 'Invitación a una party');
      expect(ChatFormat.preview(null, 'me'), '¡Escríbele!');
    });

    test('el código lleva guion en medio', () {
      expect(ChatFormat.roomCode('ABC234'), 'ABC-234');
    });
  });

  group('InviteStatus', () {
    Room room(RoomStatus status) => Room(
      id: 'sala1',
      code: 'ABC234',
      isPublic: false,
      hostUid: 'ana',
      maxPlayers: 4,
      rounds: 10,
      status: status,
      lobbyEndsAt: DateTime(2026, 10, 27),
    );

    test('solo se puede unir si la sala espera jugadores', () {
      expect(InviteStatus.of(room(RoomStatus.waiting)), InviteStatus.open);
      expect(InviteStatus.of(room(RoomStatus.waiting)).canJoin, isTrue);
      expect(InviteStatus.of(room(RoomStatus.playing)), InviteStatus.started);
      expect(InviteStatus.of(room(RoomStatus.closed)), InviteStatus.closed);
    });

    test('si la sala ya no existe, está cerrada', () {
      expect(InviteStatus.of(null), InviteStatus.closed);
      expect(InviteStatus.of(null).canJoin, isFalse);
    });
  });
}
