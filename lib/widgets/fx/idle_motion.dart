import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:party_tricks/widgets/fx/motion.dart';

/// Movimiento en reposo que se repite sin parar (respirar, tambalearse).
///
/// Son animaciones infinitas: úsalas solo en pantallas, no dentro de
/// diálogos que las pruebas cierran con `pumpAndSettle`. Se detienen solas
/// si el sistema pide reducir animaciones o si la sección está oculta
/// (`TickerMode`).
abstract class _LoopingMotion extends StatefulWidget {
  const _LoopingMotion({super.key, required this.child, required this.period});

  final Widget child;
  final Duration period;

  /// Transforma al hijo según el avance del ciclo (0 a 1).
  Widget apply(double t, Widget child);

  @override
  State<_LoopingMotion> createState() => _LoopingMotionState();
}

class _LoopingMotionState extends State<_LoopingMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.stop();
      _controller.value = 0;
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
    // Dos capas aisladas: la de afuera evita que se redibuje el resto de la
    // pantalla en cada cuadro, y la de adentro guarda el dibujo del hijo para
    // solo moverlo (sin volver a pintarlo).
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: RepaintBoundary(child: widget.child),
        builder: (context, child) => widget.apply(_controller.value, child!),
      ),
    );
  }
}

/// Crece y se encoge suavemente, como si respirara. Llama la atención sobre
/// el botón principal de una pantalla.
class Breathing extends _LoopingMotion {
  const Breathing({
    super.key,
    required super.child,
    super.period = const Duration(milliseconds: 1600),
    this.amount = 0.04,
  });

  /// Cuánto crece en el punto más alto (0.04 = 4 %).
  final double amount;

  @override
  Widget apply(double t, Widget child) {
    final wave = (1 - math.cos(2 * math.pi * t)) / 2;
    return Transform.scale(scale: 1 + amount * wave, child: child);
  }
}

/// Se tambalea un instante y luego descansa: ideal para íconos (el diamante
/// del botón "Jugar").
class Wobble extends _LoopingMotion {
  const Wobble({
    super.key,
    required super.child,
    super.period = const Duration(milliseconds: 2400),
    this.angle = 0.18,
  });

  /// Inclinación máxima, en radianes.
  final double angle;

  @override
  Widget apply(double t, Widget child) {
    // Solo se mueve en el primer 30 % del ciclo; el resto queda quieto.
    const active = 0.3;
    if (t > active) return child;
    final local = t / active;
    final damping = 1 - local;
    final rotation = angle * damping * math.sin(local * 3 * 2 * math.pi);
    return Transform.rotate(angle: rotation, child: child);
  }
}

/// Sube y baja despacio, como si flotara.
class Floating extends _LoopingMotion {
  const Floating({
    super.key,
    required super.child,
    super.period = const Duration(milliseconds: 2800),
    this.distance = 6,
  });

  /// Distancia del vaivén, en píxeles lógicos.
  final double distance;

  @override
  Widget apply(double t, Widget child) {
    final dy = -distance * math.sin(2 * math.pi * t);
    return Transform.translate(offset: Offset(0, dy), child: child);
  }
}
