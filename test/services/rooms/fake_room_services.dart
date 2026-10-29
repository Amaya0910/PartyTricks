import 'dart:async';

import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/rooms/disconnection_policy.dart';
import 'package:party_tricks/services/rooms/presence_service.dart';
import 'package:party_tricks/services/rooms/room_service.dart';

DateTime get testNow => DateTime(2026, 10, 28, 20);

/// Sala con tres jugadores: el anfitrión llegó primero, luego Ana y Beto.
Room testRoom({
  RoomPlayer? host,
  bool hostPresent = true,
  bool anaConnected = true,
  bool betoConnected = true,
  DateTime? lastActiveAt,
  RoomStatus status = RoomStatus.playing,
}) {
  final start = DateTime(2026, 10, 28, 19);
  return Room(
    id: 'sala',
    code: 'ABC234',
    isPublic: false,
    hostUid: 'host',
    maxPlayers: 4,
    rounds: 5,
    status: status,
    lobbyEndsAt: start,
    lastActiveAt: lastActiveAt,
    players: {
      if (hostPresent)
        'host':
            host ?? RoomPlayer(uid: 'host', username: 'Host', joinedAt: start),
      'ana': RoomPlayer(
        uid: 'ana',
        username: 'Ana',
        joinedAt: start.add(const Duration(seconds: 1)),
        connected: anaConnected,
        lastSeen: anaConnected ? null : start,
      ),
      'beto': RoomPlayer(
        uid: 'beto',
        username: 'Beto',
        joinedAt: start.add(const Duration(seconds: 2)),
        connected: betoConnected,
        lastSeen: betoConnected ? null : start,
      ),
    },
  );
}

/// El anfitrión desconectado desde hace [ago].
RoomPlayer hostAway(Duration ago) => RoomPlayer(
  uid: 'host',
  username: 'Host',
  joinedAt: DateTime(2026, 10, 28, 19),
  connected: false,
  lastSeen: testNow.subtract(ago),
);

/// Salas en memoria para las pruebas de desconexiones.
class FakeRoomService implements RoomService {
  final rooms = <String, Room>{};
  final _changes = StreamController<Room?>.broadcast();
  final activeGames = <String, String?>{};
  final claims = <(String, String)>[];
  final touches = <String>[];
  final left = <(String, String)>[];

  void put(Room room) {
    rooms[room.id] = room;
    _changes.add(room);
  }

  @override
  Future<bool> claimHost({
    required String roomId,
    required String expectedHost,
    required String uid,
  }) async {
    claims.add((roomId, uid));
    final room = rooms[roomId];
    if (room == null || room.hostUid != expectedHost) return false;
    put(
      Room(
        id: room.id,
        code: room.code,
        isPublic: room.isPublic,
        hostUid: uid,
        maxPlayers: room.maxPlayers,
        rounds: room.rounds,
        status: room.status,
        lobbyEndsAt: room.lobbyEndsAt,
        lastActiveAt: room.lastActiveAt,
        players: room.players,
      ),
    );
    return true;
  }

  @override
  Future<void> touch(String roomId) async => touches.add(roomId);

  @override
  Future<int> cleanAbandoned(DisconnectionPolicy policy, DateTime now) async {
    final gone = [
      for (final room in rooms.values)
        if (policy.isAbandoned(room, now)) room.id,
    ];
    gone.forEach(rooms.remove);
    return gone.length;
  }

  @override
  Future<void> setActiveGame(String uid, String? roomId) async {
    activeGames[uid] = roomId;
  }

  @override
  Stream<String?> watchActiveGame(String uid) => Stream.value(activeGames[uid]);

  @override
  Stream<Room?> watchRoom(String roomId) async* {
    yield rooms[roomId];
    yield* _changes.stream.where((room) => room?.id == roomId);
  }

  @override
  Future<void> leave({required String roomId, required String uid}) async {
    left.add((roomId, uid));
  }

  @override
  Future<Room> createRoom({
    required String uid,
    required String username,
    required RoomSettings settings,
  }) => throw UnimplementedError();

  @override
  Future<Room> joinByCode({
    required String uid,
    required String username,
    required String code,
  }) => throw UnimplementedError();

  @override
  Future<Room?> joinRandomPublic({
    required String uid,
    required String username,
  }) => throw UnimplementedError();

  @override
  Future<void> setStatus(Room room, RoomStatus status) async {}
}

/// Presencia en memoria: la hora la fija la prueba.
class FakePresenceService implements PresenceService {
  FakePresenceService([DateTime? now]) : now = now ?? testNow;

  DateTime now;
  final tracking = <(String, String)>{};

  @override
  DateTime serverNow() => now;

  @override
  void Function() track(String roomId, String uid) {
    tracking.add((roomId, uid));
    return () => tracking.remove((roomId, uid));
  }
}
