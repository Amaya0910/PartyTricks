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
    this.turnTimeout = const Duration(seconds: 40),
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

  /// Tiempo máximo que tiene un jugador para decidir en su turno (lanzar,
  /// elegir camino o salir de la tienda). Pasado ese tiempo se le salta el
  /// turno, esté conectado o no. También es lo que se espera a un jugador
  /// desconectado antes de darlo por ido.
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

  /// Si el anfitrión debe saltar el turno del jugador actual: porque no está
  /// o porque lleva [turnTimeout] sin decidir. Así la partida no se queda
  /// esperando (por ejemplo, en la tienda).
  ///
  /// [turnStartedAt] es cuándo empezó a esperarse este turno (hora del
  /// servidor); sin él solo se salta a quien no está.
  bool shouldSkipTurn(
    Room room,
    GameState game,
    DateTime now, {
    DateTime? turnStartedAt,
  }) {
    const waitingOnPlayer = {
      GamePhase.rolling,
      GamePhase.choosingBranch,
      GamePhase.shopping,
    };
    if (!waitingOnPlayer.contains(game.phase)) return false;
    if (isGone(room, game.currentPlayerId, now, turnTimeout)) return true;
    return turnStartedAt != null &&
        now.difference(turnStartedAt) >= turnTimeout;
  }

  /// Si [uid] es el único que queda en la partida: todos los demás salieron
  /// de la sala o llevan desconectados al menos [turnTimeout]. Si alguno
  /// vuelve, deja de ser verdad.
  bool isAlone(Room room, GameState game, String uid, DateTime now) {
    if (game.phase == GamePhase.finished) return false;
    final me = room.players[uid];
    if (me == null || !me.connected) return false;
    final others = game.turnOrder.where((id) => id != uid);
    if (others.isEmpty) return false;
    return others.every((id) => isGone(room, id, now, turnTimeout));
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
