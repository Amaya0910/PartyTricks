import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/room.dart';

final start = DateTime(2026, 10, 17, 12);

Room roomWith(int playerCount, {int maxPlayers = 4}) {
  return Room(
    id: 'sala1',
    code: 'ABC234',
    isPublic: false,
    hostUid: 'u0',
    maxPlayers: maxPlayers,
    rounds: 10,
    status: RoomStatus.waiting,
    lobbyEndsAt: start.add(Room.lobbyDuration),
    players: {
      for (var i = 0; i < playerCount; i++)
        'u$i': RoomPlayer(uid: 'u$i', username: 'Jugador $i', joinedAt: start),
    },
  );
}

void main() {
  test('la sala solo acepta de 2 a 6 jugadores y de 5 a 25 rondas', () {
    expect(
      () => RoomSettings(isPublic: true, maxPlayers: 1),
      throwsArgumentError,
    );
    expect(
      () => RoomSettings(isPublic: true, maxPlayers: 7),
      throwsArgumentError,
    );
    expect(() => RoomSettings(isPublic: true, rounds: 4), throwsArgumentError);
    expect(() => RoomSettings(isPublic: true, rounds: 26), throwsArgumentError);
    expect(RoomSettings(isPublic: true, maxPlayers: 2, rounds: 25).rounds, 25);
  });

  test('si se llena arranca de una', () {
    expect(roomWith(4).decide(start), LobbyDecision.start);
  });

  test('mientras no se acabe el tiempo sigue esperando', () {
    final now = start.add(const Duration(seconds: 89));
    expect(roomWith(2).decide(now), LobbyDecision.keepWaiting);
  });

  test('al acabar el tiempo arranca con 2 o más y se cierra con 1', () {
    final now = start.add(Room.lobbyDuration);
    expect(roomWith(2).decide(now), LobbyDecision.start);
    expect(roomWith(1).decide(now), LobbyDecision.close);
  });

  test('se guarda y se lee igual en la base de datos', () {
    final room = roomWith(2);
    final read = Room.fromMap('sala1', {
      'meta': room.metaToMap(),
      'players': {for (final p in room.players.values) p.uid: p.toMap()},
    });

    expect(read.code, 'ABC234');
    expect(read.status, RoomStatus.waiting);
    expect(read.lobbyEndsAt, room.lobbyEndsAt);
    expect(read.players.keys, ['u0', 'u1']);
    expect(read.players['u1']!.username, 'Jugador 1');
  });
}
