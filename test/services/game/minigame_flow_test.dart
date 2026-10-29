import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/room_guard.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/rooms/disconnection_policy.dart';

import '../game_engine/fake_random_source.dart';
import '../game_engine/test_board.dart';
import '../rooms/fake_room_services.dart';

/// La partida guardada como en Realtime Database: cada acción pasa por el
/// codec y por [hostApply], igual que en el teléfono del anfitrión.
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

/// Beto, último del orden, sale de la tienda y empieza el minijuego.
GameState _lastTurn() => const GameState(
  players: {
    'host': PlayerState(id: 'host', username: 'Host'),
    'ana': PlayerState(id: 'ana', username: 'Ana'),
    'beto': PlayerState(id: 'beto', username: 'Beto'),
  },
  turnOrder: ['host', 'ana', 'beto'],
  turnIndex: 2,
  totalRounds: 5,
  diamondTileId: 1,
  phase: GamePhase.shopping,
);

void main() {
  test('Reacción de principio a fin, guardada como en la base de datos', () {
    final table = _Table(
      GameEngine(
        board: buildTestBoard(),
        random: FakeRandomSource([3200]),
        minigames: const [MinigameType.reaction],
      ),
      _lastTurn(),
    );
    expect(table.send(const LeaveShop('beto')), isTrue);
    expect(table.state.minigame!.type, MinigameType.reaction);

    expect(
      table.send(const MinigameMove('host', 1, MinigameRules.noScore)),
      isTrue,
    );
    expect(table.send(const MinigameMove('ana', 1, 280)), isTrue);
    // Un segundo toque de Ana no cuenta.
    expect(table.send(const MinigameMove('ana', 1, 100)), isFalse);
    expect(table.send(const MinigameMove('beto', 1, 345)), isTrue);

    final state = table.state;
    expect(state.round, 2);
    expect(state.phase, GamePhase.rolling);
    expect(state.lastMinigame!.winnerIds, ['ana']);
    expect(state.players['ana']!.coins, table.engine.minigameCoins);
  });

  test('Para el Tiempo: si alguien no toca, el anfitrión cierra por tiempo y '
      'el empate se desempata con el dado', () async {
    final table = _Table(
      GameEngine(
        board: buildTestBoard(),
        random: FakeRandomSource([6, 1, 4]),
        minigames: const [MinigameType.stopwatch],
      ),
      _lastTurn(),
    );
    final presence = FakePresenceService();
    final guard = RoomGuard(
      roomId: 'sala',
      uid: 'host',
      rooms: FakeRoomService()..put(testRoom()),
      presence: presence,
      policy: const DisconnectionPolicy(),
      onMinigameTimeout: (action) async => table.send(action),
    )..update(room: testRoom());

    table.send(const LeaveShop('beto'));
    // Objetivo 6 s: Host y Ana quedan a 300 ms; Beto no toca.
    table.send(const MinigameMove('host', 1, 5700));
    table.send(const MinigameMove('ana', 1, 6300));

    guard.update(game: table.state);
    await guard.tick(); // Empieza a contar.
    presence.now = presence.now.add(
      const MinigameRules().timeLimit(table.state.minigame!),
    );
    await guard.tick();

    final result = table.state.lastMinigame!;
    expect(result.scores['beto'], MinigameRules.noScore);
    expect(result.tiebreak, {
      'host': [1],
      'ana': [4],
    });
    expect(result.winnerIds, ['ana']);
    expect(table.state.round, 2);
    guard.dispose();
  });

  test(
    'si el anfitrión se cae en pleno minijuego, el nuevo lo cierra',
    () async {
      final table = _Table(
        GameEngine(
          board: buildTestBoard(),
          random: FakeRandomSource([2500]),
          minigames: const [MinigameType.reaction],
        ),
        _lastTurn(),
      );
      table.send(const LeaveShop('beto'));
      table.send(const MinigameMove('ana', 1, 420));

      // El anfitrión se cayó sin jugar. Ana es la sucesora.
      final rooms = FakeRoomService();
      final hostGone = testRoom(host: hostAway(const Duration(seconds: 30)));
      rooms.put(hostGone);
      final presence = FakePresenceService();
      final ana = RoomGuard(
        roomId: 'sala',
        uid: 'ana',
        rooms: rooms,
        presence: presence,
        policy: const DisconnectionPolicy(),
        onMinigameTimeout: (action) async => table.send(action),
      )..update(room: hostGone, game: table.state);

      await ana.tick(); // Toma el lugar del anfitrión.
      expect(rooms.rooms['sala']!.hostUid, 'ana');
      ana.update(room: rooms.rooms['sala']);

      // Beto sigue jugando aunque cambió el anfitrión.
      expect(table.send(const MinigameMove('beto', 1, 600)), isTrue);
      ana.update(game: table.state);

      await ana.tick(); // Empieza a contar desde que lo ve.
      presence.now = presence.now.add(
        const MinigameRules().timeLimit(table.state.minigame!),
      );
      await ana.tick();

      expect(table.state.round, 2);
      expect(table.state.lastMinigame!.winnerIds, ['ana']);
      expect(table.state.lastMinigame!.scores['host'], MinigameRules.noScore);
      ana.dispose();
    },
  );

  test('quien se reconecta en pleno minijuego sigue donde iba', () {
    final table = _Table(
      GameEngine(
        board: buildTestBoard(),
        random: FakeRandomSource([40]),
        minigames: const [MinigameType.balloon],
      ),
      _lastTurn(),
    );
    table.send(const LeaveShop('beto'));
    expect(table.state.minigame!.balloonPlayer, 'host');
    table.send(const MinigameMove('host', 1, 3));

    // Ana cierra la app y vuelve: lee la partida guardada y ve su turno.
    final reloaded = table.state.minigame!;
    expect(reloaded.balloonPlayer, 'ana');
    expect(reloaded.pumps, 3);
    expect(table.send(const MinigameMove('ana', 1, 2)), isTrue);
    expect(table.state.minigame!.pumps, 5);
    expect(table.state.minigame!.balloonPlayer, 'beto');
  });

  test('quien ya estaba ausente al empezar no juega ni traba la ronda', () {
    final table = _Table(
      GameEngine(
        board: buildTestBoard(),
        random: FakeRandomSource([9]),
        minigames: const [MinigameType.stopwatch],
      ),
      _lastTurn().withPlayer(
        const PlayerState(id: 'beto', username: 'Beto', away: true),
      ),
    );
    // Beto está ausente: el anfitrión salta su turno en la tienda.
    expect(table.send(const SkipTurn('beto')), isTrue);
    expect(table.state.minigame!.players, ['host', 'ana']);

    expect(table.send(const MinigameMove('beto', 1, 9000)), isFalse);
    table.send(const MinigameMove('host', 1, 8000));
    table.send(const MinigameMove('ana', 1, 9100));
    expect(table.state.lastMinigame!.winnerIds, ['ana']);
  });
}
