import 'package:flutter/material.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Etiqueta con la rareza de un cosmético, del color de su rareza.
class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity});

  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: rarity.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pillShadow,
            blurRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        rarity.label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.white,
          shadows: [Shadow(color: AppColors.pillShadow, offset: Offset(0, 1))],
        ),
      ),
    );
  }
}
