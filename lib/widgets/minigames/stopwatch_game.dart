import 'dart:math';

import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
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
    if (!_plays) return const MinigameSpectator();
    if (score != null) {
      final late = score == MinigameRules.noScore;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MinigameFeedback(
            text: late
                ? 'Se acabó el tiempo'
                : 'Paraste en ${formatSeconds(score)}',
            icon: late ? Icons.hourglass_bottom_rounded : Icons.flag_rounded,
            color: late ? AppColors.minigameOut : null,
          ),
          const SizedBox(height: 14),
          MinigameWaiting(minigame: widget.minigame),
        ],
      );
    }
    if (_playMs < 0) return MinigameIntro(leftMs: -_playMs);
    final visible = _playMs < _rules.stopwatchVisibleMs;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigamePill(
          text: 'Objetivo: $target s',
          icon: Icons.flag_rounded,
          fontSize: 18,
        ),
        const SizedBox(height: 14),
        _Dial(
          progress: _playMs / widget.minigame.targetMs,
          label: visible ? formatSeconds(_playMs) : '¿?',
          hidden: !visible,
        ),
        if (!visible) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_off_rounded,
                size: 18,
                color: AppColors.authHint,
              ),
              const SizedBox(width: 6),
              Text(
                'El reloj se escondió',
                style: minigameTextStyle.copyWith(color: AppColors.authHint),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        MinigameButton(
          label: '¡Ya!',
          icon: Icons.touch_app_rounded,
          minWidth: 180,
          onPressed: () => _send(_playMs),
        ),
      ],
    );
  }
}

/// Cronómetro redondo: la corona arriba, las marcas alrededor y un anillo
/// que se llena hacia el objetivo. Cuando se esconde, el anillo queda
/// punteado y en el centro solo se ve "¿?".
class _Dial extends StatelessWidget {
  const _Dial({
    required this.progress,
    required this.label,
    required this.hidden,
  });

  /// De 0 a 1: cuánto falta para el objetivo.
  final double progress;
  final String label;
  final bool hidden;

  static const double _size = 184;
  static const double _compactSize = 140;

  @override
  Widget build(BuildContext context) {
    final accent = MinigameAccent.of(context);
    final size = MinigameAccent.compactOf(context) ? _compactSize : _size;
    return SizedBox(
      width: size,
      height: size + 14,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Corona del cronómetro.
          Positioned(
            top: 0,
            child: Container(
              width: 34,
              height: 18,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: minigameShade(accent), width: 2.5),
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              border: Border.all(color: accent, width: 5),
              boxShadow: [
                BoxShadow(
                  color: minigameShade(accent, 0.35),
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _DialPainter(
                progress: hidden ? 0 : progress.clamp(0, 1).toDouble(),
                accent: accent,
                hidden: hidden,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text(
                    label,
                    key: ValueKey(hidden),
                    style: minigameTextStyle.copyWith(
                      fontSize: size * (hidden ? 0.3 : 0.2),
                      fontWeight: FontWeight.w700,
                      color: hidden
                          ? AppColors.authHint
                          : minigameShade(accent),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.progress,
    required this.accent,
    required this.hidden,
  });

  final double progress;
  final Color accent;
  final bool hidden;

  static const _ticks = 12;
  static const _ring = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _ring - 4;

    // Marcas de las horas.
    final tick = Paint()
      ..color = AppColors.minigameTrack
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _ticks; i++) {
      final angle = 2 * pi * i / _ticks - pi / 2;
      final dir = Offset(cos(angle), sin(angle));
      canvas.drawLine(
        center + dir * (radius - _ring - 4),
        center + dir * (radius - _ring - (i % 3 == 0 ? 14 : 9)),
        tick,
      );
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ring
      ..strokeCap = StrokeCap.round
      ..color = hidden ? minigameTint(accent, 0.3) : AppColors.minigameTrack;

    if (hidden) {
      // Anillo punteado: ya no se sabe cuánto va.
      const dashes = 24;
      const sweep = 2 * pi / dashes;
      for (var i = 0; i < dashes; i++) {
        canvas.drawArc(rect, i * sweep, sweep * 0.45, false, track);
      }
      return;
    }

    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        track..color = accent,
      );
      // Puntito en la punta del anillo.
      final angle = 2 * pi * progress - pi / 2;
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * radius,
        _ring / 2 - 1.5,
        Paint()..color = AppColors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.hidden != hidden || old.accent != accent;
}
