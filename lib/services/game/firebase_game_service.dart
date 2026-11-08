import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/map_catalog.dart';

/// Partida en Realtime Database:
/// - `rooms/{id}/game`: el estado, lo escribe solo el anfitrión.
/// - `rooms/{id}/actions/{pushId}`: lo que piden los jugadores. El
///   anfitrión aplica cada acción y la borra en la misma escritura.
///
/// Cada partida usa el motor de su mapa: al arrancar, el de `Room.mapId`; al
/// aplicar acciones, el del `mapId` guardado en la partida.
class FirebaseGameService implements GameService {
  FirebaseGameService(this._db, this._engineFor);

  final FirebaseDatabase _db;

  /// El motor de un mapa. Lanza `UnknownMapException` si no lo conoce.
  final GameEngine Function(String mapId) _engineFor;
  final _codec = const GameCodec();

  DatabaseReference _game(String roomId) => _db.ref('rooms/$roomId/game');

  @override
  Future<void> startGame(Room room) {
    final engine = _engineFor(room.mapId);
    final rolls = initialRollsFor(room, engine.random);
    final state = engine.start(initialRolls: rolls, totalRounds: room.rounds);
    return _game(room.id).set(_codec.encodeState(state));
  }

  @override
  Future<void> sendAction(String roomId, GameAction action) {
    return _db
        .ref('rooms/$roomId/actions')
        .push()
        .set(_codec.encodeAction(action));
  }

  @override
  Stream<GameState?> watchGame(String roomId) {
    return _game(roomId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      return _codec.decodeState(value as Map<Object?, Object?>);
    });
  }

  @override
  void Function() runHost(String roomId) {
    // Las acciones se procesan en fila para que dos no lean el mismo estado.
    var queue = Future<void>.value();
    final subscription = _db.ref('rooms/$roomId/actions').onChildAdded.listen((
      event,
    ) {
      queue = queue.then((_) => _process(roomId, event.snapshot));
    });
    return subscription.cancel;
  }

  Future<void> _process(String roomId, DataSnapshot action) async {
    final updates = <String, Object?>{'actions/${action.key}': null};
    final current = await _game(roomId).get();
    final game = current.value as Map<Object?, Object?>?;
    final engine = game == null ? null : _engineOf(game);
    // Sin motor (un mapa que esta versión no tiene) la acción se descarta,
    // igual que una que no vale.
    if (game != null && engine != null && action.value != null) {
      final next = hostApply(
        engine,
        game,
        action.value as Map<Object?, Object?>,
      );
      if (next != null) updates['game'] = next;
    }
    await _db.ref('rooms/$roomId').update(updates);
  }

  GameEngine? _engineOf(Map<Object?, Object?> game) {
    try {
      return _engineFor(_codec.mapIdOf(game));
    } on UnknownMapException {
      return null;
    }
  }
}
