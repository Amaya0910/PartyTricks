import 'package:party_tricks/services/game_engine/game_state.dart';

/// Mide cuánto dura una partida y cuánto de ese tiempo fue en minijuegos.
///
/// Se le avisa cada vez que cambia la fase de la partida. El reloj se puede
/// reemplazar en las pruebas.
class MatchTimeTracker {
  MatchTimeTracker({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  DateTime? _start;
  DateTime? _end;
  DateTime? _minigameStart;
  Duration _minigameTime = Duration.zero;

  /// Avisa la fase actual. El primer aviso marca el inicio de la partida.
  void onPhase(GamePhase phase) {
    if (_end != null) return;
    final now = _clock();
    _start ??= now;

    final inMinigame = _minigameStart != null;
    if (phase == GamePhase.minigame && !inMinigame) {
      _minigameStart = now;
    } else if (phase != GamePhase.minigame && inMinigame) {
      _minigameTime += now.difference(_minigameStart!);
      _minigameStart = null;
    }

    if (phase == GamePhase.finished) _end = now;
  }

  bool get isFinished => _end != null;

  /// Desde el primer aviso hasta el final (o hasta ahora, si no ha terminado).
  Duration get playingTime {
    final start = _start;
    if (start == null) return Duration.zero;
    return (_end ?? _clock()).difference(start);
  }

  /// Suma de los minijuegos, incluido el que esté en curso.
  Duration get minigameTime {
    final running = _minigameStart;
    if (running == null) return _minigameTime;
    return _minigameTime + (_end ?? _clock()).difference(running);
  }
}
