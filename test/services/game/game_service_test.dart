import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game/game_service.dart';

import '../game_engine/fake_random_source.dart';

void main() {
  test('cada jugador de la sala lanza un dado, en orden de llegada', () {
    final start = DateTime(2026, 10, 18);
    final room = Room(
      id: 'sala1',
      code: 'ABC234',
      isPublic: false,
      hostUid: 'u1',
      maxPlayers: 4,
      rounds: 5,
      status: RoomStatus.playing,
      lobbyEndsAt: start,
      players: {
        'u2': RoomPlayer(
          uid: 'u2',
          username: 'Beto',
          joinedAt: start.add(const Duration(seconds: 5)),
        ),
        'u1': RoomPlayer(uid: 'u1', username: 'Ana', joinedAt: start),
      },
    );

    final rolls = initialRollsFor(room, FakeRandomSource([4, 6]));

    expect([for (final r in rolls) r.playerId], ['u1', 'u2']);
    expect([for (final r in rolls) r.value], [4, 6]);
    expect(rolls.last.username, 'Beto');
  });
}
