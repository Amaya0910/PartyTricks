import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game/minigame_referee.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/rooms/disconnection_policy.dart';
import 'package:party_tricks/services/rooms/presence_service.dart';
import 'package:party_tricks/services/rooms/room_service.dart';

/// Lo que corre en cada teléfono mientras está en una sala (en la espera o
/// en la partida) para que una desconexión no la deje trabada:
///
/// - Marca al jugador conectado (presencia).
/// - Si el anfitrión se fue o lleva desconectado más de lo permitido, el
///   sucesor (el conectado que llegó primero) toma su lugar.
/// - Si este teléfono es el anfitrión: avisa que la sala sigue viva, salta
///   el turno de quien esté desconectado y cierra el minijuego cuando se
///   acaba su tiempo ([MinigameReferee]).
///
/// La pantalla le pasa la sala y la partida cada vez que cambian; [tick] se
/// llama solo cada [interval] (y en las pruebas, a mano).
class RoomGuard {
  RoomGuard({
    required this.roomId,
    required this.uid,
    required this.rooms,
    required this.presence,
    required this.policy,
    this.onSkipTurn,
    this.onMinigameTimeout,
    this.onAloneChanged,
    MinigameReferee? referee,
    this.interval = const Duration(seconds: 2),
    this.heartbeat = const Duration(minutes: 1),
  }) : _referee = referee ?? MinigameReferee();

  final String roomId;
  final String uid;
  final RoomService rooms;
  final PresenceService presence;
  final DisconnectionPolicy policy;

  /// Solo en la partida: cómo pedirle al motor que salte un turno.
  final Future<void> Function(String playerId)? onSkipTurn;

  /// Solo en la partida: cómo pedirle al motor que cierre el minijuego (o
  /// infle por quien no juega) cuando se acaba el tiempo.
  final Future<void> Function(MinigameTimeout action)? onMinigameTimeout;

  /// Solo en la partida: avisa cuando este jugador se queda como el único
  /// (true) o cuando alguien vuelve y deja de estarlo (false).
  final void Function(bool alone)? onAloneChanged;
  final MinigameReferee _referee;

  final Duration interval;

  /// Cada cuánto el anfitrión renueva `lastActiveAt`.
  final Duration heartbeat;

  Room? _room;
  GameState? _game;
  void Function()? _stopPresence;
  Timer? _timer;
  DateTime? _lastTouch;
  bool _busy = false;

  /// El turno que ya se pidió saltar y cuándo, para no pedirlo dos veces
  /// seguidas (si se perdió, se vuelve a pedir pasado [retrySkip]).
  String? _skipped;
  DateTime? _skippedAt;
  static const retrySkip = Duration(seconds: 10);

  /// Cuándo se vio por primera vez el turno que se está esperando (hora del
  /// servidor). Sirve para saltarlo si el jugador sigue conectado pero no
  /// hace nada (`DisconnectionPolicy.turnTimeout`). Si cambia el anfitrión,
  /// el nuevo empieza a contar desde que lo ve.
  String? _waitingTurn;
  DateTime? _waitingSince;

  bool _alone = false;

  void start() {
    _stopPresence = presence.track(roomId, uid);
    _timer = Timer.periodic(interval, (_) => tick());
  }

  void update({Room? room, GameState? game}) {
    _room = room ?? _room;
    _game = game ?? _game;
  }

  bool get isHost => _room?.hostUid == uid;

  Future<void> tick() async {
    final room = _room;
    if (room == null || _busy) return;
    _busy = true;
    try {
      final now = presence.serverNow();
      _watchAlone(room, now);
      if (policy.successorFor(room, now) == uid) {
        await rooms.claimHost(
          roomId: roomId,
          expectedHost: room.hostUid,
          uid: uid,
        );
        return;
      }
      if (room.hostUid != uid) return;
      final last = _lastTouch;
      if (last == null || now.difference(last) >= heartbeat) {
        _lastTouch = now;
        await rooms.touch(roomId);
      }
      final game = _game;
      final closeMinigame = onMinigameTimeout;
      if (game != null && closeMinigame != null) {
        final timeout = _referee.check(game, now);
        if (timeout != null) await closeMinigame(timeout);
      }
      final skip = onSkipTurn;
      if (game == null || skip == null) return;
      final turn =
          '${game.round}/${game.turnIndex}/${game.phase.name}/'
          '${game.currentPlayerId}/${game.stepsLeft}';
      if (_waitingTurn != turn) {
        _waitingTurn = turn;
        _waitingSince = now;
      }
      if (!policy.shouldSkipTurn(
        room,
        game,
        now,
        turnStartedAt: _waitingSince,
      )) {
        return;
      }
      final at = _skippedAt;
      if (_skipped == turn && at != null && now.difference(at) < retrySkip) {
        return;
      }
      _skipped = turn;
      _skippedAt = now;
      await skip(game.currentPlayerId);
    } catch (error) {
      // Sin conexión o la regla no lo dejó todavía: se reintenta solo.
      debugPrint('RoomGuard: $error');
    } finally {
      _busy = false;
    }
  }

  /// Avisa a la pantalla cuando este jugador se queda solo o deja de estarlo.
  void _watchAlone(Room room, DateTime now) {
    final game = _game;
    final notify = onAloneChanged;
    if (game == null || notify == null) return;
    final alone = policy.isAlone(room, game, uid, now);
    if (alone == _alone) return;
    _alone = alone;
    notify(alone);
  }

  void dispose() {
    _timer?.cancel();
    _stopPresence?.call();
  }
}
