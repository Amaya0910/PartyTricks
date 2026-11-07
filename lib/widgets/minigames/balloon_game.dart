import 'dart:math';

import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Globo Bomba: por turnos, cada uno infla el globo 1, 2 o 3 veces. Nadie
/// sabe cuánto aguanta; al que se le revienta, sale. Gana el último.
class BalloonGame extends StatefulWidget {
  const BalloonGame({
    super.key,
    required this.minigame,
    required this.myId,
    required this.players,
    required this.rules,
    required this.onPlay,
  });

  final MinigameState minigame;
  final String myId;
  final MinigamePlayers players;
  final MinigameRules rules;
  final void Function(int score) onPlay;

  @override
  State<BalloonGame> createState() => _BalloonGameState();
}

class _BalloonGameState extends State<BalloonGame>
    with SingleTickerProviderStateMixin, MinigameClock {
  /// Infladas con las que el globo se ve al doble de tamaño.
  static const _pumpsToDouble = 35;

  /// Cuándo empezó el turno actual, en ms del reloj.
  int _turnStartMs = 0;

  /// El paso en el que este teléfono ya infló, para no mandar dos veces
  /// mientras llega la respuesta.
  int? _sentStep;

  /// Quién reventó el último globo, para avisarlo un momento.
  String? _popped;

  MinigameRules get _rules => widget.rules;
  MinigameState get _game => widget.minigame;

  @override
  void didUpdateWidget(BalloonGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_game.step != oldWidget.minigame.step) {
      _turnStartMs = elapsedMs;
      if (_game.out.length > oldWidget.minigame.out.length) {
        _popped = _game.out.last;
      }
    }
  }

  /// ms que le quedan al turno; el primero empieza después de la
  /// explicación.
  int get _turnLeftMs {
    final start = _game.step == 0 ? _rules.introMs : _turnStartMs;
    return _rules.balloonTurnMs - (elapsedMs - start);
  }

  void _inflate(int times) {
    if (_sentStep == _game.step) return;
    setState(() => _sentStep = _game.step);
    widget.onPlay(times);
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.balloon,
      instructions:
          'En tu turno, infla 1, 2 o 3 veces. Nadie sabe cuánto aguanta: '
          'si te revienta, quedas fuera.',
      child: _body(),
    );
  }

  Widget _body() {
    if (_game.step == 0 && elapsedMs < _rules.introMs) {
      return MinigameIntro(leftMs: _rules.introMs - elapsedMs);
    }
    final current = _game.balloonPlayer;
    final mine = current == widget.myId;
    final myTurn = mine && _sentStep != _game.step;
    final players = widget.players;
    final popped = _popped;
    final turnLeft = max(0, _turnLeftMs);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (popped != null) ...[
          MinigameAlert(
            text: '¡Reventó el globo de ${players.nameOf(popped)}!',
          ),
          const SizedBox(height: 8),
        ],
        _Balloon(
          scale: 1 + _game.pumps / _pumpsToDouble,
          color: players.colorOf(current),
          clockMs: elapsedMs,
        ),
        MinigamePill(text: 'Infladas: ${_game.pumps}', icon: Icons.air_rounded),
        const SizedBox(height: 12),
        MinigameTurnBanner(
          text: mine
              ? 'Tu turno (${turnLeft ~/ 1000 + 1} s)'
              : 'Turno de ${players.nameOf(current)}',
          color: players.colorOf(current),
          left: turnLeft / _rules.balloonTurnMs,
        ),
        const SizedBox(height: 14),
        if (myTurn)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (var times = 1; times <= _rules.maxPumps; times++)
                MinigameButton(
                  label: '+$times',
                  minWidth: 84,
                  onPressed: () => _inflate(times),
                ),
            ],
          ),
        if (_game.out.isNotEmpty) ...[
          const SizedBox(height: 12),
          MinigamePill(
            text: 'Fuera: ${_game.out.map(players.nameOf).join(', ')}',
            icon: Icons.heart_broken_rounded,
            color: AppColors.minigameOut,
            fontSize: 14,
          ),
        ],
      ],
    );
  }
}

/// El globo, más grande mientras más inflado, con el color de quien infla.
/// Se mece suave y, mientras más grande, más tiembla.
class _Balloon extends StatelessWidget {
  const _Balloon({
    required this.scale,
    required this.color,
    required this.clockMs,
  });

  final double scale;
  final Color color;

  /// ms del reloj del minijuego, para el vaivén y el temblor.
  final int clockMs;

  static const _base = 70.0;
  static const _compactBase = 50.0;
  static const _maxScale = 2.2;

  @override
  Widget build(BuildContext context) {
    final target = scale.clamp(1, _maxScale).toDouble();
    final base = MinigameAccent.compactOf(context) ? _compactBase : _base;
    final fill = Color.lerp(AppColors.balloon, color, 0.8)!;
    return SizedBox(
      height: base * _maxScale * 1.18 + _BalloonPainter.stringLength + 12,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: target),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, value, _) {
          // De 0 (desinflado) a 1 (lo más grande que se dibuja).
          final tension = ((value - 1) / (_maxScale - 1)).clamp(0.0, 1.0);
          final sway = sin(clockMs / 520) * 0.05;
          final shake = sin(clockMs / 28) * 0.035 * tension * tension;
          final width = base * value;
          return Align(
            alignment: Alignment.bottomCenter,
            child: Transform.rotate(
              angle: sway + shake,
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                size: Size(width, width * 1.18 + _BalloonPainter.stringLength),
                painter: _BalloonPainter(color: fill),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BalloonPainter extends CustomPainter {
  _BalloonPainter({required this.color});

  final Color color;

  static const stringLength = 50.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - stringLength;
    final outline = Paint()
      ..color = AppColors.characterOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    // Hilo ondulado.
    final knotY = h + 8;
    final string = Path()
      ..moveTo(w / 2, knotY)
      ..cubicTo(
        w / 2 - 12,
        knotY + stringLength * 0.35,
        w / 2 + 12,
        knotY + stringLength * 0.65,
        w / 2,
        size.height,
      );
    canvas.drawPath(
      string,
      Paint()
        ..color = AppColors.characterOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Cuerpo con forma de gota (más angosto abajo).
    final body = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.12, h * 0.86, -w * 0.02, h * 0.42, w * 0.08, h * 0.24)
      ..cubicTo(w * 0.2, h * 0.02, w * 0.8, h * 0.02, w * 0.92, h * 0.24)
      ..cubicTo(w * 1.02, h * 0.42, w * 0.88, h * 0.86, w / 2, h)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: [minigameTint(color, 0.7), color, minigameShade(color, 0.2)],
          stops: const [0, 0.6, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(body, outline);

    // Brillo.
    canvas.save();
    canvas.translate(w * 0.3, h * 0.27);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.16, height: h * 0.26),
      Paint()..color = AppColors.minigameShine,
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(w * 0.37, h * 0.47),
      w * 0.035,
      Paint()..color = AppColors.minigameShine,
    );

    // Nudo.
    final knot = Path()
      ..moveTo(w / 2, h - 1)
      ..lineTo(w / 2 - 7, h + 8)
      ..lineTo(w / 2 + 7, h + 8)
      ..close();
    canvas.drawPath(knot, Paint()..color = minigameShade(color, 0.15));
    canvas.drawPath(knot, outline..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(_BalloonPainter old) => old.color != color;
}
