import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:party_tricks/widgets/fx/motion.dart';

/// Sacude a [child] de lado a lado cada vez que cambia [trigger]. Sirve
/// para avisar de un error (contraseña incorrecta, código inválido...).
///
/// La sacudida dura un instante y se detiene sola.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  /// Cuando cambia (y no es null), se sacude.
  final Object? trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  /// Distancia máxima del movimiento, en píxeles lógicos.
  static const double _distance = 10;

  @override
  void initState() {
    super.initState();
    if (widget.trigger != null) _controller.forward();
  }

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null &&
        widget.trigger != oldWidget.trigger &&
        !Motion.reduced(context)) {
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
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        // Tres vaivenes que se van apagando.
        final dx = _distance * (1 - t) * math.sin(t * 3 * 2 * math.pi);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
