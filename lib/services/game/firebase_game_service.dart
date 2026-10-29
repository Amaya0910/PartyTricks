import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';

/// Partida en Realtime Database:
/// - `rooms/{id}/game`: el estado, lo escribe solo el anfitrión.
/// - `rooms/{id}/actions/{pushId}`: lo que piden los jugadores. El
///   anfitrión aplica cada acción y la borra en la misma escritura.
class FirebaseGameService implements GameService {
  FirebaseGameService(this._db, this._engine);

  final FirebaseDatabase _db;
  final GameEngine _engine;
  final _codec = const GameCodec();

  DatabaseReference _game(String roomId) => _db.ref('rooms/$roomId/game');

  @override
  Future<void> startGame(Room room) {
    final rolls = initialRollsFor(room, _engine.random);
    final state = _engine.start(initialRolls: rolls, totalRounds: room.rounds);
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
    if (current.value != null && action.value != null) {
      final next = hostApply(
        _engine,
        current.value as Map<Object?, Object?>,
        action.value as Map<Object?, Object?>,
      );
      if (next != null) updates['game'] = next;
    }
    await _db.ref('rooms/$roomId').update(updates);
  }
}
