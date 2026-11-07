import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Cuenta Rápida: en el tablero salen cuentas con dos respuestas posibles.
/// Las buenas suman, y más si vas en racha; las malas restan. Todos resuelven
/// las mismas cuentas.
class QuickMathGame extends MinigameWidget {
  const QuickMathGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<QuickMathGame> createState() => _QuickMathGameState();
}

class _QuickMathGameState extends State<QuickMathGame>
    with SingleTickerProviderStateMixin, MinigameClock, MinigameSolo {
  static const int _penalty = 5;
  static const int _wrongMs = 420;

  late final List<MathProblem> _problems = quickMathScript(
    game.seed,
    rules.quickMathProblems,
  );

  int _index = 0;
  int _points = 0;
  int _streak = 0;
  int _gained = 0;
  int _wrongAtMs = -100000;

  /// Si acaba de fallar: no se puede responder un momento.
  bool get _locked => playMs - _wrongAtMs < _wrongMs;

  @override
  void onClock() {
    if (playing && playMs >= rules.quickMathMs) sendScore(_points);
  }

  void _answer(bool left) {
    if (!playing || _locked) return;
    final problem = _problems[_index];
    final right = left == problem.leftIsRight;
    right ? HapticFeedback.selectionClick() : HapticFeedback.heavyImpact();
    setState(() {
      if (right) {
        _streak++;
        _gained = quickMathPoints(_streak);
        _points += _gained;
      } else {
        _streak = 0;
        _gained = -_penalty;
        _points = max(0, _points - _penalty);
        _wrongAtMs = playMs;
      }
      _index = (_index + 1) % _problems.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.quickMath,
      instructions: 'Toca la respuesta correcta. ¡Las malas restan puntos!',
      child: soloBody(
        arena: _arena,
        doneText: (score) => '¡$score puntos!',
        doneIcon: Icons.calculate_rounded,
      ),
    );
  }

  Widget _arena(BuildContext context) {
    final problem = _problems[_index];
    final compact = MinigameAccent.compactOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            MinigameCounter(value: '$_points', icon: Icons.star_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: MinigameTimeBar(left: 1 - playMs / rules.quickMathMs),
            ),
            if (_streak >= 2) ...[
              const SizedBox(width: 10),
              MinigameCounter(
                value: 'x$_streak',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.coin,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Transform.translate(
          offset: _locked
              ? minigameShake(playMs - _wrongAtMs, durationMs: _wrongMs)
              : Offset.zero,
          child: _Chalkboard(
            problem: problem,
            index: _index,
            gained: _gained,
            wrong: _locked,
            height: compact ? 150 : 190,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _answerButton(problem.left, true)),
            const SizedBox(width: 10),
            Expanded(child: _answerButton(problem.right, false)),
          ],
        ),
      ],
    );
  }

  Widget _answerButton(int value, bool left) {
    return MinigameButton(
      label: '$value',
      minWidth: 0,
      fontSize: 30,
      color: left ? AppColors.blueStrong : AppColors.minigameRhythm,
      onPressed: _locked ? null : () => _answer(left),
    );
  }
}

/// Pizarra con marco de madera y la cuenta escrita con tiza.
class _Chalkboard extends StatelessWidget {
  const _Chalkboard({
    required this.problem,
    required this.index,
    required this.gained,
    required this.wrong,
    required this.height,
  });

  final MathProblem problem;
  final int index;
  final int gained;
  final bool wrong;
  final double height;

  @override
  Widget build(BuildContext context) {
    final board = wrong ? AppColors.chalkboardWrong : AppColors.chalkboard;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: board,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.chestPartyStrong, width: 8),
        boxShadow: [
          BoxShadow(
            color: minigameShade(AppColors.chestPartyStrong, 0.4),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _SmudgePainter()),
            ),
            TweenAnimationBuilder<double>(
              key: ValueKey(index),
              tween: Tween(begin: 0.72, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${problem.text} = ?',
                    style: minigameTextStyle.copyWith(
                      fontSize: height * 0.32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.chalk,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            if (gained != 0)
              Positioned(
                right: 12,
                bottom: 8,
                child: MinigameFloat(
                  key: ValueKey('puntos-$index'),
                  text: gained > 0 ? '+$gained' : '$gained',
                  color: gained > 0
                      ? AppColors.medalGold
                      : AppColors.pillBackground,
                  fontSize: 22,
                  rise: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Manchas de tiza borrada.
class _SmudgePainter extends CustomPainter {
  const _SmudgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final smudge = Paint()
      ..color = AppColors.chalk.withValues(alpha: 0.06)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        Offset(size.width * 0.08, size.height * 0.24),
        Offset(size.width * 0.46, size.height * 0.14),
        smudge,
      )
      ..drawLine(
        Offset(size.width * 0.6, size.height * 0.84),
        Offset(size.width * 0.94, size.height * 0.72),
        smudge,
      );
  }

  @override
  bool shouldRepaint(_SmudgePainter oldDelegate) => false;
}
