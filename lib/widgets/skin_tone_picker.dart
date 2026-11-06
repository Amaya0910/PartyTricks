import 'package:flutter/material.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Cuadrícula con los tonos de piel. No conoce Riverpod: recibe el tono
/// elegido y avisa cuando tocan otro.
class SkinTonePicker extends StatelessWidget {
  const SkinTonePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: SkinTone.count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _ToneDot(
        index: index,
        isSelected: index == selected,
        onTap: () => onSelected(index),
      ),
    );
  }
}

class _ToneDot extends StatelessWidget {
  const _ToneDot({
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Tono ${index + 1}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: SkinTone.colorOf(index),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.blueStrong : AppColors.wardrobeInk,
              width: isSelected ? 4 : 1,
            ),
          ),
          child: isSelected
              ? const Icon(Icons.check, color: AppColors.blueStrong)
              : null,
        ),
      ),
    );
  }
}
