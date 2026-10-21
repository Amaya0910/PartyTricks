import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Interruptor privado (verde, a la izquierda) / público (azul, a la derecha).
class AnimatedModeSwitch extends StatelessWidget {
  const AnimatedModeSwitch({
    super.key,
    required this.isPrivate,
    required this.onChanged,
  });

  final bool isPrivate;
  final ValueChanged<bool> onChanged;

  static const _duration = Duration(milliseconds: 380);
  static const _curve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isPrivate),
      child: Container(
        width: 92,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.sliderInactive,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.switchBorder),
        ),
        child: AnimatedAlign(
          duration: _duration,
          curve: _curve,
          alignment:
              isPrivate ? Alignment.centerLeft : Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 0.52,
            heightFactor: 1,
            child: AnimatedContainer(
              duration: _duration,
              curve: _curve,
              decoration: BoxDecoration(
                color: isPrivate
                    ? AppColors.switchGreen
                    : AppColors.authAccent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: AnimatedSwitcher(
                duration: _duration,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: RotationTransition(
                    turns: Tween(begin: 0.25, end: 0.0).animate(animation),
                    child: child,
                  ),
                ),
                child: Icon(
                  isPrivate
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  key: ValueKey(isPrivate),
                  size: 24,
                  color: isPrivate
                      ? AppColors.switchGreenIcon
                      : AppColors.headerBorder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}