import 'package:flutter/widgets.dart';

/// Se encoge al presionarlo y vuelve con un rebote. Para cosas tocables que
/// no son botones con relieve (avatares, tarjetas, íconos).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.9,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Escala mientras se mantiene presionado.
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 450),
  );

  late final Animation<double> _scale =
      Tween<double>(begin: 1, end: widget.pressedScale).animate(
        CurvedAnimation(
          parent: _press,
          curve: Curves.easeOut,
          reverseCurve: Curves.elasticIn,
        ),
      );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _press.forward() : null,
      onTapUp: enabled ? (_) => _press.reverse() : null,
      onTapCancel: enabled ? _press.reverse : null,
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
