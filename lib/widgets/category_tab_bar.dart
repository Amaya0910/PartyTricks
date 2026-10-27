import 'package:flutter/material.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/theme/app_colors.dart';

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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.wardrobeChip,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[category], size: 30, color: color),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
  CosmeticCategory.shirt: Icons.checkroom,
  CosmeticCategory.pants: Icons.dry_cleaning,
  CosmeticCategory.shoes: Icons.hiking,
  CosmeticCategory.hair: Icons.content_cut,
  CosmeticCategory.nose: Icons.face,
  CosmeticCategory.eyes: Icons.visibility,
  CosmeticCategory.mouth: Icons.sentiment_satisfied,
};