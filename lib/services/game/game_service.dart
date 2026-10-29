import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/services/game_engine/turn_order_resolver.dart';

/// La partida en vivo. El teléfono del creador ("anfitrión") aplica las
/// reglas; los demás solo mandan acciones y miran el estado.
abstract class GameService {
  /// Solo el anfitrión: hace la tirada inicial y guarda el estado inicial.
  Future<void> startGame(Room room);

  /// Cualquier jugador: pide hacer algo (lanzar el dado, elegir camino...).
  Future<void> sendAction(String roomId, GameAction action);

  /// El estado de la partida en vivo. Emite null mientras no ha empezado.
  Stream<GameState?> watchGame(String roomId);

  /// Solo el anfitrión: procesa las acciones que llegan, una por una.
  /// Devuelve una función para dejar de escuchar.
  void Function() runHost(String roomId);
}

/// Tirada inicial: cada jugador de la sala lanza un dado de 6.
List<InitialRoll> initialRollsFor(Room room, RandomSource random) {
  final players = room.players.values.toList()
    ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
  return [
    for (final player in players)
      InitialRoll(
        playerId: player.uid,
        username: player.username,
        value: random.rollDie(),
      ),
  ];
}

/// Lo que hace el anfitrión con cada acción que llega: lee el estado
/// guardado, aplica la acción y devuelve el estado nuevo para guardar.
///
/// Devuelve null si la acción no vale ahora (alguien tocó el dado dos veces,
/// no era su turno, no le alcanzan las monedas...) o si no se entiende.
Map<String, Object?>? hostApply(
  GameEngine engine,
  Map<Object?, Object?> game,
  Map<Object?, Object?> action,
) {
  const codec = GameCodec();
  try {
    final next = engine.apply(
      codec.decodeState(game),
      codec.decodeAction(action),
    );
    return codec.encodeState(next);
  } on StateError {
    return null;
  } on FormatException {
    return null;
  }
}
