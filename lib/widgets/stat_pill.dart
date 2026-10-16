import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Cápsula con un ícono y un número (monedas o diamantes).
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}