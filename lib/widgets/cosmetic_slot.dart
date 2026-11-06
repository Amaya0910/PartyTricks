import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Espacio de un cosmético con borde punteado. Si [label] y [preview] son
/// null, está vacío. El [semanticLabel] solo lo lee el lector de pantalla. El seleccionado lleva el borde azul.
class CosmeticSlot extends StatelessWidget {
  const CosmeticSlot({
    super.key,
    this.label,
    this.semanticLabel,
    this.preview,
    this.isSelected = false,
    this.onTap,
  });

  final String? label;

  /// Nombre para el lector de pantalla cuando no se muestra [label].
  final String? semanticLabel;

  /// Dibujo del cosmético (va encima del [label]).
  final Widget? preview;

  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: isSelected ? AppColors.blueStrong : AppColors.wardrobeInk,
            strokeWidth: isSelected ? 3 : 2,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (preview != null) Expanded(child: preview!),
                if (label != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontSize: preview == null ? 14 : 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.blueStrong
                            : AppColors.wardrobeInk,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Borde punteado redondeado (Vestuario y Tienda).
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    this.radius = 4,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
