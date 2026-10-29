import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/room_guard.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/rooms/disconnection_policy.dart';

import '../services/rooms/fake_room_services.dart';

GameState shoppingTurnOf(String uid) {
  const order = ['host', 'ana', 'beto'];
  return GameState(
    players: const {
      'host': PlayerState(id: 'host', username: 'Host'),
      'ana': PlayerState(id: 'ana', username: 'Ana'),
      'beto': PlayerState(id: 'beto', username: 'Beto'),
    },
    turnOrder: order,
    turnIndex: order.indexOf(uid),
    totalRounds: 5,
    diamondTileId: 1,
    phase: GamePhase.shopping,
  );
}

void main() {
  late FakeRoomService rooms;
  late FakePresenceService presence;
  late List<String> skipped;

  RoomGuard guardFor(String uid, {bool inGame = true}) {
    return RoomGuard(
      roomId: 'sala',
      uid: uid,
      rooms: rooms,
      presence: presence,
      policy: const DisconnectionPolicy(),
      onSkipTurn: inGame ? (id) async => skipped.add(id) : null,
    );
  }

  setUp(() {
    rooms = FakeRoomService();
    presence = FakePresenceService();
    skipped = [];
  });

  test('marca la presencia mientras está en la sala', () {
    final guard = guardFor('ana')..start();
    expect(presence.tracking, {('sala', 'ana')});

    guard.dispose();
    expect(presence.tracking, isEmpty);
  });

  test('si el anfitrión se cae, el sucesor toma su lugar', () async {
    final room = testRoom(host: hostAway(const Duration(seconds: 30)));
    rooms.put(room);
    final ana = guardFor('ana')..update(room: room);
    final beto = guardFor('beto')..update(room: room);

    await beto.tick();
    expect(rooms.claims, isEmpty, reason: 'Beto no es el sucesor');

    await ana.tick();
    expect(rooms.claims, [('sala', 'ana')]);
    expect(rooms.rooms['sala']!.hostUid, 'ana');
  });

  test(
    'si el anfitrión solo perdió la conexión un momento, nadie lo toma',
    () async {
      final room = testRoom(host: hostAway(const Duration(seconds: 3)));
      final ana = guardFor('ana')..update(room: room);

      await ana.tick();
      expect(rooms.claims, isEmpty);
    },
  );

  test(
    'el anfitrión avisa que la sala sigue viva, una vez por minuto',
    () async {
      final guard = guardFor('host')..update(room: testRoom());

      await guard.tick();
      await guard.tick();
      expect(rooms.touches, ['sala']);

      presence.now = testNow.add(const Duration(minutes: 1));
      await guard.tick();
      expect(rooms.touches, ['sala', 'sala']);
    },
  );

  test('el anfitrión salta el turno de quien se cayó en la tienda', () async {
    final guard = guardFor(
      'host',
    )..update(room: testRoom(anaConnected: false), game: shoppingTurnOf('ana'));

    await guard.tick();
    await guard.tick();
    // Se pide una sola vez mientras la partida no cambie...
    expect(skipped, ['ana']);

    // ...y se vuelve a pedir si se perdió.
    presence.now = testNow.add(RoomGuard.retrySkip);
    await guard.tick();
    expect(skipped, ['ana', 'ana']);
  });

  test('no salta el turno de un jugador conectado', () async {
    final guard = guardFor('host')
      ..update(room: testRoom(), game: shoppingTurnOf('ana'));

    await guard.tick();
    expect(skipped, isEmpty);
  });

  test('solo el anfitrión salta turnos', () async {
    final guard = guardFor(
      'beto',
    )..update(room: testRoom(anaConnected: false), game: shoppingTurnOf('ana'));

    await guard.tick();
    expect(skipped, isEmpty);
    expect(rooms.touches, isEmpty);
  });

  test('en la sala de espera no hay turnos que saltar', () async {
    final guard = guardFor('host', inGame: false)
      ..update(room: testRoom(status: RoomStatus.waiting));

    await guard.tick();
    expect(rooms.touches, ['sala']);
    expect(skipped, isEmpty);
  });

  test('si algo falla, no se cae y lo intenta en el siguiente tick', () async {
    final guard = RoomGuard(
      roomId: 'sala',
      uid: 'host',
      rooms: rooms,
      presence: presence,
      policy: const DisconnectionPolicy(),
      onSkipTurn: (_) async => throw Exception('sin conexión'),
    )..update(room: testRoom(anaConnected: false), game: shoppingTurnOf('ana'));

    await expectLater(guard.tick(), completes);
  });
}
