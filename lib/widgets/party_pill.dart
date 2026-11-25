import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Etiqueta azul redondeada con sombra ("Tu código", "Jugadores: 3").
/// Solo dibuja.
class PartyPill extends StatelessWidget {
  const PartyPill({
    super.key,
    required this.label,
    this.color = AppColors.authAccent,
    this.widthFactor,
    this.fontSize = 17,
  });

  final String label;
  final Color color;

  /// Si se da, ocupa esa fracción del ancho; si no, lo que mida el texto.
  final double? widthFactor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pillShadow,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: AppColors.white,
          shadows: const [
            Shadow(color: AppColors.headerBorder, offset: Offset(0, 1.5)),
          ],
        ),
      ),
    );
    final factor = widthFactor;
    return Align(
      alignment: Alignment.centerLeft,
      child: factor == null
          ? pill
          : FractionallySizedBox(widthFactor: factor, child: pill),
    );
  }
}
