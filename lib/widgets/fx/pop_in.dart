import 'package:flutter/widgets.dart';
import 'package:party_tricks/widgets/fx/motion.dart';

/// Hace aparecer a [child] con un rebote: se desvanece, crece y se desliza
/// desde [from] hasta su lugar.
///
/// Corre una sola vez al montarse. La espera ([delay]) es parte de la misma
/// animación (no usa temporizadores), así que las pruebas con
/// `pumpAndSettle` terminan sin problemas.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.entrance,
    this.from = const Offset(0, 0.25),
    this.startScale = 0.85,
  }) : index = 0;

  /// Atajo para listas: el elemento [index] entra un poco después del
  /// anterior.
  const PopIn.staggered({
    super.key,
    required this.index,
    required this.child,
    Duration base = Duration.zero,
    this.duration = Motion.entrance,
    this.from = const Offset(0, 0.25),
    this.startScale = 0.85,
  }) : delay = base;

  final Widget child;

  /// Espera antes de empezar (en las listas, la del primer elemento).
  final Duration delay;

  /// Posición en una lista: cada uno espera [Motion.stagger] más.
  final int index;
  final Duration duration;

  /// Desplazamiento inicial, en fracciones del tamaño del hijo.
  final Offset from;

  /// Escala inicial.
  final double startScale;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final Duration _delay = widget.delay + Motion.stagger * widget.index;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _delay + widget.duration,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(_delayFraction, 1, curve: Motion.pop),
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Interval(_delayFraction, 1, curve: Curves.easeOut),
  );

  double get _delayFraction {
    final total = (_delay + widget.duration).inMicroseconds;
    return total == 0 ? 0 : _delay.inMicroseconds / total;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
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
        final t = _progress.value;
        return FractionalTranslation(
          translation: widget.from * (1 - t),
          child: Transform.scale(
            scale: widget.startScale + (1 - widget.startScale) * t,
            child: Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
