import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tarjeta con dos caras que da una vuelta para mostrar la otra.
///
/// Las dos caras siempre están en el árbol (solo se pinta una), así conservan
/// lo que el jugador escribió al voltear. No sabe nada de su contenido.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.showBack,
    this.duration = const Duration(milliseconds: 600),
  });

  final Widget front;
  final Widget back;

  /// false muestra [front] y true muestra [back]. Al cambiar, se anima.
  final bool showBack;

  final Duration duration;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  /// Qué tanto se nota la perspectiva al girar.
  static const double _perspective = 0.0012;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.showBack ? 1 : 0,
  );

  late final Animation<double> _turn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBack == widget.showBack) return;
    if (widget.showBack) {
      _controller.forward();
    } else {
      _controller.reverse();
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
      animation: _turn,
      builder: (context, _) {
        final turn = _turn.value;
        // La cara cambia justo cuando la tarjeta está de canto.
        final frontVisible = turn < 0.5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateY(turn * math.pi),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Offstage(offstage: !frontVisible, child: widget.front),
              // La cara de atrás se gira una media vuelta para no verse
              // en espejo.
              Offstage(
                offstage: frontVisible,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: widget.back,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
