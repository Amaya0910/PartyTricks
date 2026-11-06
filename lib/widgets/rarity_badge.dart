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
      ),
      child: Text(
        rarity.label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
    );
  }
}
