import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/animated_count.dart';

/// Cápsula con un ícono y un número (monedas o diamantes). El número cuenta
/// hasta su nuevo valor cuando cambia.
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
      padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pillShadow,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: color,
            shadows: const [
              Shadow(color: AppColors.pillShadow, offset: Offset(0, 1.5)),
            ],
          ),
          const SizedBox(width: 6),
          AnimatedCount(
            value: value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
