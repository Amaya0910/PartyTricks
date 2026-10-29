import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Para el Tiempo: se ve el objetivo y el reloj corriendo los primeros
/// segundos; luego el reloj se esconde y hay que tocar "¡Ya!" cuando creas
/// que se llegó al objetivo. Solo cuenta el primer toque.
class StopwatchGame extends StatefulWidget {
  const StopwatchGame({
    super.key,
    required this.minigame,
    required this.myId,
    required this.rules,
    required this.onPlay,
  });

  final MinigameState minigame;
  final String myId;
  final MinigameRules rules;
  final void Function(int score) onPlay;

  @override
  State<StopwatchGame> createState() => _StopwatchGameState();
}

class _StopwatchGameState extends State<StopwatchGame>
    with SingleTickerProviderStateMixin, MinigameClock {
  /// Lo que mandó este teléfono, para no mandarlo dos veces.
  int? _sent;

  MinigameRules get _rules => widget.rules;
  int get _playMs => elapsedMs - _rules.introMs;
  bool get _plays => widget.minigame.players.contains(widget.myId);

  /// Lo que ya mandó (aquí o antes de reconectarse).
  int? get _myScore => _sent ?? widget.minigame.scores[widget.myId];

  @override
  void onClock() {
    // Se acabó el tiempo sin tocar: no vale.
    if (_plays && _myScore == null && _playMs >= _rules.stopwatchLimitMs) {
      _send(MinigameRules.noScore);
    }
  }

  void _send(int score) {
    if (_myScore != null) return;
    setState(() => _sent = score);
    stopClock();
    widget.onPlay(score);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.minigame.targetMs ~/ 1000;
    return MinigameCard(
      type: MinigameType.stopwatch,
      instructions:
          'Toca ¡Ya! cuando creas que pasaron $target segundos. '
          'El reloj se esconde a los '
          '${_rules.stopwatchVisibleMs ~/ 1000} segundos.',
      child: _body(target),
    );
  }

  Widget _body(int target) {
    final score = _myScore;
    if (!_plays) {
      return const Text('Este minijuego lo ves desde fuera.');
    }
    if (score != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score == MinigameRules.noScore
                ? 'Se acabó el tiempo'
                : 'Paraste en ${formatSeconds(score)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          MinigameWaiting(minigame: widget.minigame),
        ],
      );
    }
    if (_playMs < 0) return MinigameIntro(leftMs: -_playMs);
    final visible = _playMs < _rules.stopwatchVisibleMs;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Objetivo: $target s',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          visible ? formatSeconds(_playMs) : '¿?',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        if (!visible) const Text('El reloj se escondió'),
        const SizedBox(height: 16),
        MinigameButton(label: '¡Ya!', onPressed: () => _send(_playMs)),
      ],
    );
  }
}
