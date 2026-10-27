import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Deslizador de puntos. Dibuja un punto por cada valor entre [start] y [max],
/// pero solo deja elegir valores desde [min]. Los puntos hasta [value] van
/// rellenos.
class StepDotSlider extends StatelessWidget {
  const StepDotSlider({
    super.key,
    required this.start,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.dotSize = 14,
    this.showLine = true,
  });

  final int start;
  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;
  final double dotSize;

  /// Si es false solo se dibujan los puntos (como en "Rondas").
  final bool showLine;

  static const _animation = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final count = max - start + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final step = (constraints.maxWidth - dotSize) / (count - 1);

        void select(double dx) {
          final index = ((dx - dotSize / 2) / step).round();
          final selected = (start + index).clamp(min, max);
          if (selected != value) onChanged(selected);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => select(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => select(d.localPosition.dx),
          child: SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (showLine) ...[
                  Positioned(
                    left: dotSize / 2,
                    right: dotSize / 2,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.sliderInactive,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: dotSize / 2,
                    child: AnimatedContainer(
                      duration: _animation,
                      curve: Curves.easeOut,
                      width: (value - start) * step,
                      height: 5,
                      color: AppColors.authAccent,
                    ),
                  ),
                ],
                for (var i = 0; i < count; i++)
                  Positioned(
                    left: i * step,
                    child: AnimatedContainer(
                      duration: _animation,
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: start + i <= value
                            ? AppColors.authAccent
                            : AppColors.sliderInactive,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}