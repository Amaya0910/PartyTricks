import 'package:flutter/material.dart';
import 'package:party_tricks/services/feedback/haptics.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Botón con relieve al estilo de los juegos de fiesta: una cara de color
/// sobre un canto más oscuro. Al tocarlo, la cara se hunde y rebota.
///
/// Solo dibuja y avisa del toque; no sabe qué hace el botón. Si [onPressed]
/// es null, se ve apagado y no responde.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.color,
    required this.onPressed,
    required this.child,
    this.edgeColor,
    this.borderColor,
    this.radius = 18,
    this.depth = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.semanticLabel,
  });

  /// Color de la cara del botón.
  final Color color;

  /// Color del canto. Si es null, se oscurece [color].
  final Color? edgeColor;

  /// Borde de la cara. Si es null, no tiene borde.
  final Color? borderColor;

  final VoidCallback? onPressed;
  final Widget child;
  final double radius;

  /// Alto del canto: cuánto se hunde la cara al presionar.
  final double depth;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton>
    with SingleTickerProviderStateMixin {
  // 0 = suelto, 1 = hundido del todo.
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 420),
  );

  late final Animation<double> _sink = CurvedAnimation(
    parent: _press,
    curve: Curves.easeOut,
    reverseCurve: Curves.elasticIn,
  );

  bool get _enabled => widget.onPressed != null;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (!_enabled) return;
    _press.forward();
    HapticsScope.of(context).tap();
  }

  void _up() {
    if (_enabled) _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    final edge =
        widget.edgeColor ?? Color.alphaBlend(AppColors.edgeShade, widget.color);
    final border = widget.borderColor;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          opacity: _enabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 200),
          child: AnimatedBuilder(
            animation: _sink,
            builder: (context, child) {
              // Puede pasar un poco de 0 por el rebote: por eso se traslada
              // en vez de cambiar el tamaño.
              final pressed = _sink.value;
              return Stack(
                children: [
                  // El canto: queda fijo debajo de la cara.
                  Positioned.fill(
                    top: widget.depth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: edge,
                        borderRadius: radius,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pillShadow,
                            blurRadius: (6 - 4 * pressed).clamp(0, 6),
                            offset: Offset(0, (4 - 3 * pressed).clamp(0, 4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: widget.depth),
                    child: Transform.translate(
                      offset: Offset(0, widget.depth * pressed),
                      child: child,
                    ),
                  ),
                ],
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: radius,
                border: border == null
                    ? null
                    : Border.all(color: border, width: 2),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  children: [
                    // Reflejo en la mitad de arriba: da volumen a la cara.
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [AppColors.gloss, Color(0x00FFFFFF)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: widget.padding, child: widget.child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
