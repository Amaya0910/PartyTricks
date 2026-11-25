import 'package:flutter/material.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/pressable_scale.dart';

/// Barra horizontal con las categorías de cosméticos. Se desplaza si no caben.
/// No conoce Riverpod: recibe la categoría activa y avisa cuando tocan otra.
class CategoryTabBar extends StatelessWidget {
  const CategoryTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CosmeticCategory selected;
  final ValueChanged<CosmeticCategory> onSelected;

  static const double _height = 84;
  static const double _tabWidth = 76;

  @override
  Widget build(BuildContext context) {
    const categories = CosmeticCategory.values;

    return Container(
      height: _height,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.screenBackground, width: 2),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _Tab(
            category: category,
            width: _tabWidth,
            isSelected: category == selected,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.category,
    required this.width,
    required this.isSelected,
    required this.onTap,
  });

  final CosmeticCategory category;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.blueStrong : AppColors.wardrobeInk;

    return Semantics(
      button: true,
      selected: isSelected,
      label: category.label,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: width,
          // La elegida queda blanca con borde azul y "levantada".
          margin: EdgeInsets.only(bottom: isSelected ? 4 : 0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.white : AppColors.wardrobeChip,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.blueStrong : AppColors.wardrobeChip,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? AppColors.blueStrong : AppColors.pillShadow,
                blurRadius: 0,
                offset: Offset(0, isSelected ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Al elegirla, el ícono da un salto elástico.
              TweenAnimationBuilder<double>(
                key: ValueKey(isSelected),
                tween: Tween(begin: isSelected ? 0.6 : 1.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Icon(_icons[category], size: 30, color: color),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Íconos provisionales: reemplazar por los exportados de Figma.
const Map<CosmeticCategory, IconData> _icons = {
  CosmeticCategory.skin: Icons.palette,
  CosmeticCategory.shirt: Icons.checkroom,
  CosmeticCategory.pants: Icons.dry_cleaning,
  CosmeticCategory.shoes: Icons.hiking,
  CosmeticCategory.hair: Icons.content_cut,
  CosmeticCategory.nose: Icons.face,
  CosmeticCategory.eyes: Icons.visibility,
  CosmeticCategory.mouth: Icons.sentiment_satisfied,
  CosmeticCategory.accessory: Icons.auto_awesome,
};
