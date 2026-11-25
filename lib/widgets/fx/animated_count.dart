import 'package:flutter/material.dart';

/// Número que cuenta hasta su nuevo valor y da un saltito al cambiar.
/// Sirve para monedas, diamantes y puntajes.
class AnimatedCount extends StatefulWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 650),
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _bump.forward(from: 0);
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bump,
      builder: (context, child) {
        // Sube rápido y vuelve con rebote.
        final t = _bump.value;
        final scale = 1 + 0.25 * (t < 0.3 ? t / 0.3 : (1 - t) / 0.7);
        return Transform.scale(
          scale: _bump.isAnimating ? scale : 1,
          child: child,
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: widget.value.toDouble()),
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) =>
            Text('${value.round()}', style: widget.style),
      ),
    );
  }
}
