import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/motion.dart';

/// Texto con tres puntos que saltan uno detrás de otro ("Cargando...").
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key, required this.label});

  final String label;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  static const _style = TextStyle(
    color: AppColors.white,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
    shadows: [Shadow(color: AppColors.blueStrong, offset: Offset(0, 2))],
  );

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

  /// Altura del salto del punto [index] en este momento.
  double _jump(int index) {
    final t = (_controller.value - index * 0.15) % 1;
    if (t > 0.4) return 0;
    final local = t / 0.4;
    return -8 * (1 - (2 * local - 1) * (2 * local - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(widget.label, style: _style),
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(0, _jump(i)),
                  child: const Text('.', style: _style),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
