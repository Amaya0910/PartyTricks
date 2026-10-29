import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Reacción: sale "Prepárate" y, después de una espera al azar, "¡YA!". Gana
/// el que toca más rápido. Si tocas antes, quedas fuera.
class ReactionGame extends StatefulWidget {
  const ReactionGame({
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
  State<ReactionGame> createState() => _ReactionGameState();
}

class _ReactionGameState extends State<ReactionGame>
    with SingleTickerProviderStateMixin, MinigameClock {
  int? _sent;

  /// Si este teléfono tocó antes del "¡YA!".
  bool _falseStart = false;

  MinigameRules get _rules => widget.rules;

  /// ms desde que salió "¡YA!" (negativo mientras se espera).
  int get _sinceGo => elapsedMs - _rules.introMs - widget.minigame.delayMs;
  bool get _started => elapsedMs >= _rules.introMs;
  bool get _plays => widget.minigame.players.contains(widget.myId);
  int? get _myScore => _sent ?? widget.minigame.scores[widget.myId];

  @override
  void onClock() {
    if (_plays && _myScore == null && _sinceGo >= _rules.reactionLimitMs) {
      _send(MinigameRules.noScore);
    }
  }

  void _send(int score) {
    if (_myScore != null) return;
    setState(() => _sent = score);
    stopClock();
    widget.onPlay(score);
  }

  /// Tocar antes del "¡YA!" te deja fuera. Durante la explicación no cuenta.
  void _tap() {
    if (!_plays || _myScore != null || !_started) return;
    _falseStart = _sinceGo < 0;
    _send(_falseStart ? MinigameRules.noScore : _sinceGo);
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.reaction,
      instructions:
          'Toca el recuadro apenas veas ¡YA!. Si tocas antes, quedas fuera.',
      child: _body(),
    );
  }

  Widget _body() {
    final score = _myScore;
    if (!_plays) return const Text('Este minijuego lo ves desde fuera.');
    if (score != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            switch (score) {
              MinigameRules.noScore when _falseStart =>
                '¡Te adelantaste! Quedas fuera',
              MinigameRules.noScore => 'Tu jugada no cuenta',
              _ => 'Tardaste $score ms',
            },
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          MinigameWaiting(minigame: widget.minigame),
        ],
      );
    }
    if (!_started) {
      return MinigameIntro(leftMs: _rules.introMs - elapsedMs);
    }
    final go = _sinceGo >= 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Al apoyar el dedo, sin esperar a que lo levante.
      onTapDown: (_) => _tap(),
      child: Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: go ? AppColors.reactionGo : AppColors.reactionWait,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          go ? '¡YA!' : 'Prepárate...',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
