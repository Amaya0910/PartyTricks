import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Espacio de un cosmético con borde punteado. Si [label] es null, está vacío.
class CosmeticSlot extends StatelessWidget {
  const CosmeticSlot({super.key, this.label, this.onTap});

  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Center(
          child: label == null
              ? null
              : Padding(
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label!, style: const TextStyle(fontSize: 14)),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  static const double _strokeWidth = 2;
  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = AppColors.wardrobeInk;

    final rect = (Offset.zero & size).deflate(_strokeWidth / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}