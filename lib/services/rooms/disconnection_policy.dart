import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';

/// Qué hacer cuando alguien se desconecta. Los tiempos se pueden cambiar
/// (ver `disconnectionPolicyProvider`).
///
/// No depende de Firebase: recibe la sala y la hora del servidor, así se
/// prueba sola. La hora tiene que ser la del servidor porque `lastSeen` la
/// pone el servidor.
class DisconnectionPolicy {
  const DisconnectionPolicy({
    this.hostTimeout = const Duration(seconds: 15),
    this.turnTimeout = const Duration(seconds: 30),
    this.abandonedAfter = const Duration(hours: 2),
  });

  /// Lo mínimo que exigen las reglas de la base de datos para tomar el
  /// lugar del anfitrión (`database.rules.json`, `meta`).
  static const minHostTimeout = Duration(seconds: 10);

  /// Lo que exigen las reglas para borrar una sala abandonada.
  static const minAbandonedAfter = Duration(hours: 2);

  /// Cuánto se espera al anfitrión desconectado antes de reemplazarlo. No
  /// puede ser menor que [minHostTimeout]; si lo es, se usa el mínimo.
  final Duration hostTimeout;

  /// Cuánto se espera a un jugador desconectado antes de saltar su turno.
  final Duration turnTimeout;

  /// Sin nadie conectado y sin señales del anfitrión por este tiempo, la
  /// sala se puede borrar. No puede ser menor que [minAbandonedAfter].
  final Duration abandonedAfter;

  /// Si [uid] ya no está: salió de la sala o lleva desconectado al menos
  /// [timeout]. Sin `lastSeen` (salas viejas) se toma como ido.
  bool isGone(Room room, String uid, DateTime now, Duration timeout) {
    final player = room.players[uid];
    if (player == null) return true;
    if (player.connected) return false;
    final seen = player.lastSeen;
    return seen == null || now.difference(seen) >= timeout;
  }

  /// Quién debe tomar el lugar del anfitrión, o null si no hace falta (o no
  /// hay nadie conectado). Es el jugador conectado que llegó primero, así
  /// todos los teléfonos eligen al mismo.
  String? successorFor(Room room, DateTime now) {
    final wait = hostTimeout < minHostTimeout ? minHostTimeout : hostTimeout;
    if (!isGone(room, room.hostUid, now, wait)) return null;
    final candidates =
        room.players.values
            .where((p) => p.connected && p.uid != room.hostUid)
            .toList()
          ..sort((a, b) {
            final byTime = a.joinedAt.compareTo(b.joinedAt);
            return byTime != 0 ? byTime : a.uid.compareTo(b.uid);
          });
    return candidates.isEmpty ? null : candidates.first.uid;
  }

  /// Si el anfitrión debe saltar el turno del jugador actual porque no está.
  /// Así la partida no se queda esperando (por ejemplo, en la tienda).
  bool shouldSkipTurn(Room room, GameState game, DateTime now) {
    const waitingOnPlayer = {
      GamePhase.rolling,
      GamePhase.choosingBranch,
      GamePhase.shopping,
    };
    if (!waitingOnPlayer.contains(game.phase)) return false;
    return isGone(room, game.currentPlayerId, now, turnTimeout);
  }

  /// Si la sala quedó abandonada: nadie conectado y sin señales del
  /// anfitrión (o, si nunca dio, desde que se acabó la espera).
  bool isAbandoned(Room room, DateTime now) {
    if (room.players.values.any((p) => p.connected)) return false;
    final last = room.lastActiveAt ?? room.lobbyEndsAt;
    final wait = abandonedAfter < minAbandonedAfter
        ? minAbandonedAfter
        : abandonedAfter;
    return now.difference(last) >= wait;
  }
}
