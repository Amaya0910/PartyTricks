import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Barra de progreso con relleno de aspecto líquido y el porcentaje encima.
/// No conoce Riverpod: recibe el avance (0.0 a 1.0).
class LiquidProgressBar extends StatefulWidget {
  const LiquidProgressBar({
    super.key,
    required this.progress,
    this.height = 26,
  });

  final double progress;
  final double height;

  @override
  State<LiquidProgressBar> createState() => _LiquidProgressBarState();
}

class _LiquidProgressBarState extends State<LiquidProgressBar>
    with SingleTickerProviderStateMixin {
  // Controla el movimiento de las ondas; no tiene relación con el avance.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.progress.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, _) {
        final percent = (value * 100).round();
        return Semantics(
          label: 'Cargando',
          value: '$percent%',
          excludeSemantics: true,
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LiquidPainter(progress: value, wave: _wave),
              child: Center(
                child: Text(
                  '$percent%',
                    style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: AppColors.blueStrong, blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({required this.progress, required this.wave})
      : super(repaint: wave);

  final double progress;
  final Animation<double> wave;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );

    canvas.drawRRect(rrect, Paint()..color = AppColors.blueMain);

    if (progress > 0) {
      canvas.save();
      canvas.clipRRect(rrect);

      final phase = wave.value * 2 * math.pi;
      final amplitude = size.height * 0.2;

      // Capa de atrás: el mismo color más transparente y desfasado,
      // da profundidad al líquido.
      _drawLiquid(
        canvas,
        size,
        phase: phase + math.pi / 2,
        amplitude: amplitude,
        color: AppColors.blueLight.withValues(alpha: 0.55),
      );
      // Capa de adelante.
      _drawLiquid(
        canvas,
        size,
        phase: phase,
        amplitude: amplitude * 0.8,
        color: AppColors.blueLight,
      );

      canvas.restore();
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.blueStrong,
    );
  }

  /// Dibuja el relleno desde la izquierda hasta un borde ondulado.
  void _drawLiquid(
    Canvas canvas,
    Size size, {
    required double phase,
    required double amplitude,
    required Color color,
  }) {
    // En 0 % el borde queda fuera por la izquierda y en 100 % fuera por la
    // derecha, para que la onda nunca deje huecos en los extremos.
    final edge = -amplitude + progress * (size.width + 2 * amplitude);

    double edgeAt(double y) =>
        edge + amplitude * math.sin(2 * math.pi * y / size.height + phase);

    final path = Path()..moveTo(0, 0);
    for (double y = 0; y <= size.height; y += 2) {
      path.lineTo(edgeAt(y), y);
    }
    path
      ..lineTo(edgeAt(size.height), size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LiquidPainter oldDelegate) =>
      oldDelegate.progress != progress;
}