import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:party_tricks/services/feedback/haptics.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/motion.dart';

/// Una explosión de confeti que sale del centro y cae. Corre una sola vez
/// (no se repite), así que sirve también dentro de diálogos.
///
/// Usa los colores de los jugadores, que ya son parte de la app.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.pieces = 36,
    this.duration = const Duration(milliseconds: 1600),
    this.seed = 7,
  });

  final int pieces;
  final Duration duration;

  /// Semilla fija: el confeti cae igual cada vez (y en las pruebas).
  final int seed;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// Para vibrar una sola vez aunque cambien las dependencias.
  bool _celebrated = false;

  late final List<_Piece> _pieces = _Piece.scatter(
    count: widget.pieces,
    random: math.Random(widget.seed),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed && !_celebrated) {
      _celebrated = true;
      HapticsScope.of(context).success();
      if (!Motion.reduced(context)) _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_controller, _pieces),
        ),
      ),
    );
  }
}

/// Un papelito: hacia dónde sale, qué tan rápido, su color y cómo gira.
class _Piece {
  const _Piece({
    required this.angle,
    required this.speed,
    required this.color,
    required this.spin,
    required this.size,
  });

  final double angle;
  final double speed;
  final Color color;
  final double spin;
  final double size;

  static List<_Piece> scatter({
    required int count,
    required math.Random random,
  }) {
    const colors = AppColors.players;
    return [
      for (var i = 0; i < count; i++)
        _Piece(
          // Sobre todo hacia arriba, abriéndose en abanico.
          angle: -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.2,
          speed: 0.55 + random.nextDouble() * 0.6,
          color: colors[i % colors.length],
          spin: (random.nextDouble() - 0.5) * 14,
          size: 5 + random.nextDouble() * 5,
        ),
    ];
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.animation, this.pieces) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t == 0 || t == 1) return;
    final center = size.center(Offset.zero);
    final reach = size.shortestSide * 0.75;
    final paint = Paint();
    // Se desvanece en el último tercio.
    final fade = t < 0.66 ? 1.0 : (1 - t) / 0.34;

    for (final piece in pieces) {
      // Sale disparado, frena y la gravedad lo baja.
      final travel = reach * piece.speed * Curves.easeOutCubic.transform(t);
      final gravity = reach * 0.9 * t * t;
      final position =
          center +
          Offset(
            math.cos(piece.angle) * travel,
            math.sin(piece.angle) * travel + gravity,
          );
      paint.color = piece.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(piece.spin * t)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: piece.size,
              height: piece.size * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}
