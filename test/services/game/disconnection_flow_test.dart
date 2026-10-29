import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/room_guard.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'package:party_tricks/services/rooms/disconnection_policy.dart';

import '../game_engine/fake_random_source.dart';
import '../game_engine/test_board.dart';
import '../rooms/fake_room_services.dart';

/// La partida guardada como en Realtime Database, y quién la está
/// procesando (el anfitrión del momento).
class _Table {
  _Table(this.engine, GameState start) : _stored = codec.encodeState(start);

  static const codec = GameCodec();
  final GameEngine engine;
  Map<String, Object?> _stored;

  GameState get state => codec.decodeState(_stored);

  bool send(GameAction action) {
    final next = hostApply(engine, _stored, codec.encodeAction(action));
    if (next == null) return false;
    _stored = next;
    return true;
  }
}

Room _room({
  required String hostUid,
  required Map<String, bool> connected,
  required DateTime seen,
}) {
  final start = DateTime(2026, 10, 28, 19);
  const order = ['host', 'ana', 'beto'];
  return Room(
    id: 'sala',
    code: 'ABC234',
    isPublic: false,
    hostUid: hostUid,
    maxPlayers: 4,
    rounds: 2,
    status: RoomStatus.playing,
    lobbyEndsAt: start,
    players: {
      for (final (i, uid) in order.indexed)
        uid: RoomPlayer(
          uid: uid,
          username: uid,
          joinedAt: start.add(Duration(seconds: i)),
          connected: connected[uid] ?? true,
          lastSeen: connected[uid] ?? true ? null : seen,
        ),
    },
  );
}

void main() {
  test(
    'el anfitrión y Ana se caen con Ana en la tienda: la partida sigue',
    () async {
      // Tablero de prueba: tienda en la 12. Ana parte de la 10.
      final engine = GameEngine(
        board: buildTestBoard(),
        random: FakeRandomSource([1, 2, 1, 1, 1]),
      );
      final table = _Table(
        engine,
        const GameState(
          players: {
            'host': PlayerState(id: 'host', username: 'Host', coins: 10),
            'ana': PlayerState(
              id: 'ana',
              username: 'Ana',
              position: 10,
              coins: 10,
            ),
            'beto': PlayerState(id: 'beto', username: 'Beto', coins: 10),
          },
          turnOrder: ['host', 'ana', 'beto'],
          totalRounds: 2,
          diamondTileId: 41,
        ),
      );
      final rooms = FakeRoomService();
      final presence = FakePresenceService();
      const policy = DisconnectionPolicy();

      // Ronda 1: el anfitrión juega; Ana cae en la tienda y compra.
      expect(table.send(const RollDice('host')), isTrue);
      expect(table.send(const RollDice('ana')), isTrue);
      expect(table.state.phase, GamePhase.shopping);
      expect(table.send(const BuyItem('ana', ShopItem.shield)), isTrue);

      // Se caen el anfitrión y Ana a la vez.
      final dropped = presence.now;
      rooms.put(
        _room(
          hostUid: 'host',
          connected: {'host': false, 'ana': false},
          seen: dropped,
        ),
      );
      final beto = RoomGuard(
        roomId: 'sala',
        uid: 'beto',
        rooms: rooms,
        presence: presence,
        policy: policy,
        onSkipTurn: (id) async => table.send(SkipTurn(id)),
      )..update(room: rooms.rooms['sala'], game: table.state);

      // Al principio se espera: puede ser un corte corto.
      await beto.tick();
      expect(rooms.rooms['sala']!.hostUid, 'host');
      expect(table.state.phase, GamePhase.shopping);

      // Pasado el tiempo, Beto (el único conectado) toma el anfitrión...
      presence.now = dropped.add(policy.hostTimeout);
      await beto.tick();
      expect(rooms.rooms['sala']!.hostUid, 'beto');

      // ...y cuando se cumple la espera del turno, saca a Ana de la tienda.
      presence.now = dropped.add(policy.turnTimeout);
      beto.update(room: rooms.rooms['sala'], game: table.state);
      await beto.tick();
      var state = table.state;
      expect(state.phase, GamePhase.rolling);
      expect(state.currentPlayerId, 'beto');
      expect(state.players['ana']!.away, isTrue);

      // Beto juega su turno con normalidad.
      expect(table.send(const RollDice('beto')), isTrue);
      expect(table.send(const FinishMinigame(['beto'])), isTrue);

      // Ronda 2: el anfitrión viejo sigue fuera; Beto le salta el turno.
      beto.update(game: table.state);
      await beto.tick();
      expect(table.state.currentPlayerId, 'ana');

      // Ana vuelve: recupera monedas, ítems y posición, y juega.
      rooms.put(
        _room(hostUid: 'beto', connected: {'host': false}, seen: dropped),
      );
      beto.update(room: rooms.rooms['sala'], game: table.state);
      await beto.tick();
      expect(table.state.currentPlayerId, 'ana', reason: 'no se le salta');
      state = table.state;
      final ana = state.players['ana']!;
      expect(ana.position, 12);
      expect(ana.coins, 5);
      expect(ana.itemCount(ShopItem.shield), 1);

      expect(table.send(const RollDice('ana')), isTrue);
      expect(table.state.players['ana']!.away, isFalse);
      expect(table.send(const RollDice('beto')), isTrue);
      expect(table.send(const FinishMinigame([])), isTrue);
      final end = table.state;
      expect(end.phase, GamePhase.finished);

      // El que no volvió termina sin XP; Ana, que volvió, sí cuenta normal.
      final results = const MatchResultsBuilder().build(end);
      expect(results.of('host')!.disconnected, isTrue);
      expect(results.of('host')!.experience, 0);
      expect(results.of('host')!.player.missedTurns, 1);
      expect(results.of('ana')!.disconnected, isFalse);
      expect(results.of('ana')!.player.missedTurns, 1);
    },
  );

  test('si nadie toma el anfitrión, las acciones esperan en la fila', () {
    // Mientras no hay anfitrión nadie aplica nada; cuando llega uno, las
    // acciones pendientes se aplican en orden (runHost las recibe todas).
    final engine = GameEngine(
      board: buildTestBoard(),
      random: FakeRandomSource([2, 2]),
    );
    final table = _Table(
      engine,
      const GameState(
        players: {
          'a': PlayerState(id: 'a', username: 'Ana'),
          'b': PlayerState(id: 'b', username: 'Beto'),
        },
        turnOrder: ['a', 'b'],
        totalRounds: 2,
        diamondTileId: 41,
      ),
    );
    final pending = [const RollDice('a'), const RollDice('b')];

    for (final action in pending) {
      expect(table.send(action), isTrue);
    }
    expect(table.state.phase, GamePhase.minigame);
  });
}
