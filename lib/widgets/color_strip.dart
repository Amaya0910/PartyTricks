import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Línea horizontal de colores que se desplaza si no caben. No conoce
/// Riverpod: recibe la posición elegida y avisa cuando tocan otra.
class ColorStrip extends StatelessWidget {
  const ColorStrip({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelected,
    this.firstIsNone = false,
  });

  final List<Color> colors;

  /// Si el primer color es "sin color" (el dibujo original): se marca con una
  /// X roja.
  final bool firstIsNone;
  final int selected;
  final ValueChanged<int> onSelected;

  static const double _swatch = 34;
  static const double _height = 50;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.screenBackground, width: 2),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: colors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) => Center(
          child: _Swatch(
            color: colors[index],
            label: firstIsNone && index == 0
                ? 'Sin color'
                : 'Color ${index + 1}',
            isNone: firstIsNone && index == 0,
            size: _swatch,
            isSelected: index == selected,
            onTap: () => onSelected(index),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.size,
    required this.isSelected,
    required this.onTap,
    this.isNone = false,
  });

  final bool isNone;
  final Color color;
  final String label;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // El check se ve sobre colores claros y oscuros.
    final checkColor = color.computeLuminance() > 0.5
        ? AppColors.wardrobeInk
        : AppColors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.blueStrong : AppColors.wardrobeInk,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: isNone
              ? Icon(Icons.close_rounded, size: 24, color: Colors.red.shade600)
              : isSelected
              ? Icon(Icons.check, size: 18, color: checkColor)
              : null,
        ),
      ),
    );
  }
}
