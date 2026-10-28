import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Un código en cuadritos blancos, como "Tu codigo" del mockup de Ajustes.
class CodeDigits extends StatelessWidget {
  const CodeDigits({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final char in code.split(''))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AspectRatio(
                aspectRatio: 0.75,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.settingsRowBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.slotBorder,
                        blurRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          char,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
