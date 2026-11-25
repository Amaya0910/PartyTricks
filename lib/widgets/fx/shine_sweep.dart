import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/motion.dart';

/// Un destello diagonal que cruza a [child] cada cierto tiempo.
///
/// Es una animación infinita: no la pongas dentro de diálogos que las
/// pruebas cierran con `pumpAndSettle`.
class ShineSweep extends StatefulWidget {
  const ShineSweep({
    super.key,
    required this.child,
    this.radius = 18,
    this.period = const Duration(milliseconds: 3200),
  });

  final Widget child;

  /// Redondeo de las esquinas, para que el destello no se salga.
  final double radius;

  /// Cada cuánto pasa el destello (incluye la pausa).
  final Duration period;

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  /// Parte del ciclo en la que el destello se mueve; el resto es pausa.
  static const double _sweepFraction = 0.35;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El destello va en su propia capa: el botón de abajo no se repinta.
    return Stack(
      children: [
        RepaintBoundary(child: widget.child),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.radius),
                child: CustomPaint(painter: _ShinePainter(_controller)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShinePainter extends CustomPainter {
  _ShinePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value / _ShineSweepState._sweepFraction;
    if (t >= 1 || animation.isDismissed) return;

    final band = size.height * 0.9;
    final x =
        -band * 2 + (size.width + band * 3) * Curves.easeInOut.transform(t);
    final path = Path()
      ..moveTo(x, size.height)
      ..lineTo(x + band, 0)
      ..lineTo(x + band * 1.6, 0)
      ..lineTo(x + band * 0.6, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: const [Color(0x00FFFFFF), AppColors.shine, Color(0x00FFFFFF)],
        ).createShader(Rect.fromLTWH(x, 0, band * 1.6, size.height)),
    );
  }

  @override
  bool shouldRepaint(_ShinePainter oldDelegate) => false;
}
