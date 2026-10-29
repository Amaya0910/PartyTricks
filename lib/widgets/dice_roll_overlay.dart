import 'dart:math';

import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Una tirada para mostrar. [serial] cambia en cada tirada, aunque salga
/// el mismo número.
class DiceRoll {
  const DiceRoll({
    required this.serial,
    required this.username,
    required this.color,
    required this.value,
    this.extra = 0,
    this.boost = 0,
  });

  final int serial;
  final String username;

  /// Color del jugador que lanzó.
  final Color color;

  /// Lo que salió en el dado normal, y el dado extra y el impulso (0 si
  /// no se usaron).
  final int value;
  final int extra;
  final int boost;

  int get total => value + extra + boost;
}

/// El dado que cae girando sobre el mapa y muestra lo que salió.
///
/// Solo es para verse: el número ya lo decidió el juego. No tapa los toques
/// del mapa y se quita solo al terminar.
class DiceRollOverlay extends StatefulWidget {
  const DiceRollOverlay({super.key, required this.roll});

  /// La última tirada, o null si todavía no hay.
  final DiceRoll? roll;

  @override
  State<DiceRollOverlay> createState() => _DiceRollOverlayState();
}

class _DiceRollOverlayState extends State<DiceRollOverlay>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2400);

  /// Partes de la animación, de 0 a 1: cae girando, rebota con el número,
  /// se queda y se desvanece.
  static const _tumbleEnd = 0.40;
  static const _popEnd = 0.50;
  static const _fadeStart = 0.85;

  /// Mientras gira pasan caras del 1 a este número.
  static const _tumbleFaces = 6;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void didUpdateWidget(DiceRollOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final roll = widget.roll;
    if (roll != null && roll.serial != oldWidget.roll?.serial) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roll = widget.roll;
    if (roll == null || !_controller.isAnimating) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dieSize = (constraints.biggest.shortestSide * 0.28)
              .clamp(64.0, 120.0)
              .toDouble();
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _frame(roll, dieSize, _controller.value),
          );
        },
      ),
    );
  }

  Widget _frame(DiceRoll roll, double dieSize, double t) {
    final opacity = t < _fadeStart
        ? 1.0
        : 1 - (t - _fadeStart) / (1 - _fadeStart);
    final double angle;
    final double drop;
    final double scale;
    final int face;
    if (t < _tumbleEnd) {
      final p = t / _tumbleEnd;
      // Gira dos vueltas frenando y termina derecho.
      angle = (1 - Curves.easeOutCubic.transform(p)) * 4 * pi;
      drop = (1 - Curves.bounceOut.transform(p)) * -dieSize * 1.5;
      scale = 0.6 + 0.4 * Curves.easeOut.transform(p);
      // Cambia de cara cada poco, como si rodara.
      face = (p * 14).floor() * 5 % _tumbleFaces + 1;
    } else {
      angle = 0;
      drop = 0;
      face = roll.value;
      scale = t < _popEnd
          ? 1 + 0.25 * sin(pi * (t - _tumbleEnd) / (_popEnd - _tumbleEnd))
          : 1;
    }
    final landed = t >= _tumbleEnd;
    return Opacity(
      opacity: opacity.clamp(0, 1).toDouble(),
      child: ColoredBox(
        color: AppColors.diceScrim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(0, drop),
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scale: scale,
                    child: _Die(size: dieSize, value: face, color: roll.color),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: landed ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: _Label(roll: roll),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un dado blanco con el número grande del color del jugador. Lleva número
/// y no puntos porque con efectos puede salir hasta 12.
class _Die extends StatelessWidget {
  const _Die({required this.size, required this.value, required this.color});

  final double size;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, AppColors.characterOutline, 0.5)!,
            offset: Offset(0, size * 0.07),
          ),
          const BoxShadow(
            color: AppColors.characterShadow,
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: size * 0.55,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

/// "Ana sacó 4", y debajo cuánto avanza si hubo dado extra o impulso.
class _Label extends StatelessWidget {
  const _Label({required this.roll});

  final DiceRoll roll;

  @override
  Widget build(BuildContext context) {
    final bonus = [
      if (roll.extra > 0) '+${roll.extra} dado extra',
      if (roll.boost > 0) '+${roll.boost} impulso',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.boardPanel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${roll.username} sacó ${roll.value}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (bonus.isNotEmpty)
            Text(
              '${bonus.join(' · ')} = avanza ${roll.total}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
        ],
      ),
    );
  }
}
