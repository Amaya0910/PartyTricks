import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/room_controller.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/services/rooms/room_service.dart';

/// Servicio de salas falso: guarda todo en memoria, sin Firebase.
class FakeRoomService implements RoomService {
  final rooms = <String, Room>{};

  @override
  Future<Room> createRoom({
    required String uid,
    required String username,
    required RoomSettings settings,
  }) async {
    final now = DateTime(2026, 10, 17);
    final room = Room(
      id: 'sala${rooms.length + 1}',
      code: 'ABC234',
      isPublic: settings.isPublic,
      hostUid: uid,
      maxPlayers: settings.maxPlayers,
      rounds: settings.rounds,
      status: RoomStatus.waiting,
      lobbyEndsAt: now.add(Room.lobbyDuration),
      players: {uid: RoomPlayer(uid: uid, username: username, joinedAt: now)},
    );
    rooms[room.id] = room;
    return room;
  }

  @override
  Future<Room> joinByCode({
    required String uid,
    required String username,
    required String code,
  }) async {
    throw const RoomException('No existe una sala con ese código');
  }

  @override
  Future<Room?> joinRandomPublic({
    required String uid,
    required String username,
  }) async => null;

  @override
  Future<void> leave({required String roomId, required String uid}) async {}

  @override
  Future<void> setStatus(Room room, RoomStatus status) async {}

  @override
  Stream<Room?> watchRoom(String roomId) => Stream.value(rooms[roomId]);
}

ProviderContainer containerWith(FakeRoomService service) {
  final container = ProviderContainer(
    overrides: [
      roomServiceProvider.overrideWithValue(service),
      roomIdentityProvider.overrideWith(
        (ref) async => const RoomIdentity(uid: 'u1', username: 'Brayan'),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('crea la sala con el jugador actual como creador', () async {
    final container = containerWith(FakeRoomService());
    final controller = container.read(roomControllerProvider.notifier);

    final room = await controller.create(RoomSettings(isPublic: false));

    expect(room.hostUid, 'u1');
    expect(room.players['u1']!.username, 'Brayan');
    expect(container.read(roomControllerProvider), isFalse);
  });

  test('si el código no existe avisa con un mensaje', () async {
    final container = containerWith(FakeRoomService());
    final controller = container.read(roomControllerProvider.notifier);

    await expectLater(
      controller.joinByCode('ZZZ999'),
      throwsA(isA<RoomException>()),
    );
    expect(container.read(roomControllerProvider), isFalse);
  });

  test('si no hay salas públicas devuelve null', () async {
    final container = containerWith(FakeRoomService());
    final controller = container.read(roomControllerProvider.notifier);

    expect(await controller.joinRandom(), isNull);
  });
}
