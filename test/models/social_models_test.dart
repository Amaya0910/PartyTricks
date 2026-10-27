import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/models/social/chat_summary.dart';
import 'package:party_tricks/models/social/friendship.dart';
import 'package:party_tricks/models/social/party_invite.dart';
import 'package:party_tricks/models/social/public_profile.dart';

void main() {
  final at = DateTime(2026, 10, 27, 18, 30);

  group('Friendship', () {
    const request = Friendship(
      id: 'a_b',
      members: ['a', 'b'],
      requestedBy: 'a',
      status: FriendshipStatus.pending,
    );

    test('el otro jugador depende de quién mira', () {
      expect(request.otherOf('a'), 'b');
      expect(request.otherOf('b'), 'a');
    });

    test('una solicitud es enviada para uno y recibida para el otro', () {
      expect(request.isOutgoingFor('a'), isTrue);
      expect(request.isIncomingFor('a'), isFalse);
      expect(request.isIncomingFor('b'), isTrue);
      expect(request.isOutgoingFor('b'), isFalse);
    });

    test('aceptada no es ni enviada ni recibida', () {
      const friends = Friendship(
        id: 'a_b',
        members: ['a', 'b'],
        requestedBy: 'a',
        status: FriendshipStatus.accepted,
      );

      expect(friends.isAccepted, isTrue);
      expect(friends.isIncomingFor('b'), isFalse);
      expect(friends.isOutgoingFor('a'), isFalse);
    });

    test('toMap y fromMap son inversos', () {
      final original = Friendship(
        id: 'a_b',
        members: const ['a', 'b'],
        requestedBy: 'b',
        status: FriendshipStatus.accepted,
        createdAt: at,
      );

      final copy = Friendship.fromMap('a_b', original.toMap());

      expect(copy.members, ['a', 'b']);
      expect(copy.requestedBy, 'b');
      expect(copy.status, FriendshipStatus.accepted);
      expect(copy.createdAt, at);
    });
  });

  test('ChatMessage: toMap y fromMap son inversos (también invitaciones)', () {
    final invite = ChatMessage(
      id: 'm1',
      senderId: 'a',
      text: '¡Te invito!',
      sentAt: at,
      type: MessageType.invite,
      roomId: 'sala1',
      roomCode: 'ABC234',
    );

    final copy = ChatMessage.fromMap('m1', invite.toMap());

    expect(copy.senderId, 'a');
    expect(copy.text, '¡Te invito!');
    expect(copy.sentAt, at);
    expect(copy.isInvite, isTrue);
    expect(copy.roomId, 'sala1');
    expect(copy.roomCode, 'ABC234');
  });

  group('ChatSummary sin leer', () {
    ChatSummary chat({required String sender, DateTime? readAt}) {
      return ChatSummary.fromMap('a_b', {
        'members': ['a', 'b'],
        'lastMessage': ChatMessage(
          id: '',
          senderId: sender,
          text: 'Hola',
          sentAt: at,
        ).toMap(),
        'lastReadAt': {if (readAt != null) 'a': readAt.millisecondsSinceEpoch},
      });
    }

    test('un mensaje del otro que no he abierto está sin leer', () {
      expect(chat(sender: 'b').hasUnreadFor('a'), isTrue);
    });

    test('si lo abrí después del mensaje, está leído', () {
      final read = chat(
        sender: 'b',
        readAt: at.add(const Duration(minutes: 1)),
      );
      expect(read.hasUnreadFor('a'), isFalse);
    });

    test('mis propios mensajes nunca quedan sin leer para mí', () {
      expect(chat(sender: 'a').hasUnreadFor('a'), isFalse);
    });

    test('un chat sin mensajes no tiene nada sin leer', () {
      const empty = ChatSummary(id: 'a_b', members: ['a', 'b']);
      expect(empty.hasUnreadFor('a'), isFalse);
    });
  });

  test('PartyInvite: toMap y fromMap son inversos', () {
    final invite = PartyInvite(
      id: 'i1',
      fromUid: 'a',
      fromName: 'Ana',
      toUid: 'b',
      roomId: 'sala1',
      roomCode: 'ABC234',
      sentAt: at,
    );

    final copy = PartyInvite.fromMap('i1', invite.toMap());

    expect(copy.fromName, 'Ana');
    expect(copy.toUid, 'b');
    expect(copy.roomCode, 'ABC234');
    expect(copy.sentAt, at);
    expect(copy.seen, isFalse);
  });

  test('PublicProfile: sameAs compara todos los campos', () {
    const a = PublicProfile(uid: 'u', username: 'Ana', experience: 10);
    const b = PublicProfile(uid: 'u', username: 'Ana', experience: 10);
    const c = PublicProfile(uid: 'u', username: 'Ana', experience: 20);

    expect(a.sameAs(b), isTrue);
    expect(a.sameAs(c), isFalse);
    expect(PublicProfile.fromMap('u', a.toMap()).sameAs(a), isTrue);
  });
}
