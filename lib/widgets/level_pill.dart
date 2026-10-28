import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Cápsula amarilla con la corona y el nivel del jugador, como en el mockup.
class LevelPill extends StatelessWidget {
  const LevelPill({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, size: 18, color: AppColors.coin),
          const SizedBox(width: 6),
          Text(
            '$level',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
