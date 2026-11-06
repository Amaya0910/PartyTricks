import 'dart:math';

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
    if (!_plays) return const MinigameSpectator();
    if (score != null) {
      final fail = score == MinigameRules.noScore;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MinigameFeedback(
            text: switch (score) {
              MinigameRules.noScore when _falseStart =>
                '¡Te adelantaste! Quedas fuera',
              MinigameRules.noScore => 'Tu jugada no cuenta',
              _ => 'Tardaste $score ms',
            },
            icon: fail ? Icons.front_hand_rounded : Icons.bolt_rounded,
            color: fail ? AppColors.minigameOut : null,
          ),
          const SizedBox(height: 14),
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
      child: _Pad(go: go, sinceGoMs: _sinceGo, waitMs: elapsedMs),
    );
  }
}

/// El recuadro para tocar: rojo con un reloj de arena mientras se espera y
/// verde con una mano cuando sale "¡YA!". El color cambia de golpe para que
/// nadie tenga ventaja.
class _Pad extends StatelessWidget {
  const _Pad({required this.go, required this.sinceGoMs, required this.waitMs});

  final bool go;

  /// ms desde el "¡YA!" (negativo mientras se espera).
  final int sinceGoMs;

  /// ms del reloj, para que los puntitos de la espera respiren.
  final int waitMs;

  static const double _height = 210;
  static const double _compactHeight = 160;
  static const double _depth = 8;

  @override
  Widget build(BuildContext context) {
    final color = go ? AppColors.reactionGo : AppColors.reactionWait;
    final height = MinigameAccent.compactOf(context) ? _compactHeight : _height;
    // Rebote corto al salir "¡YA!".
    final pop = go && sinceGoMs < 220 ? sin(pi * sinceGoMs / 220) * 0.12 : 0.0;
    // El reloj de arena se mece suave mientras se espera.
    final sway = go ? 0.0 : sin(waitMs / 260) * 0.18;
    return Container(
      width: double.infinity,
      height: height + _depth,
      padding: const EdgeInsets.only(bottom: _depth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.1,
            colors: [minigameTint(color, 0.75), color],
          ),
          border: Border.all(color: AppColors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: minigameShade(color, 0.35),
              offset: const Offset(0, _depth),
            ),
            const BoxShadow(
              color: AppColors.pillShadow,
              blurRadius: 10,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anillos suaves de fondo.
            for (final size in [height * 0.9, height * 0.62])
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.18),
                    width: 3,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Transform.scale(
                  scale: 1 + pop,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: sway,
                        child: Icon(
                          go
                              ? Icons.touch_app_rounded
                              : Icons.hourglass_top_rounded,
                          color: AppColors.white,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        go ? '¡YA!' : 'Prepárate...',
                        style: minigameTextStyle.copyWith(
                          fontSize: go ? 48 : 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          shadows: [
                            Shadow(
                              color: minigameShade(color, 0.5),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      if (!go)
                        Text(
                          'No toques todavía',
                          style: minigameTextStyle.copyWith(
                            fontSize: 14,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
