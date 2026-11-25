import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/chunky_button.dart';

/// Botón de acción con relieve y texto blanco de juego (con ícono opcional).
///
/// Es el botón común de la app: "Crear", "Salir", "Lanzar dado"... Para
/// botones con contenido especial usa [ChunkyButton] directamente.
class PartyButton extends StatelessWidget {
  const PartyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.authAccent,
    this.edgeColor = AppColors.headerBorder,
    this.fontSize = 20,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Color de la cara.
  final Color color;

  /// Color del canto y de la sombra del texto.
  final Color? edgeColor;
  final double fontSize;

  /// Alto total, canto incluido.
  final double height;

  static const double _depth = 5;

  @override
  Widget build(BuildContext context) {
    final edge = edgeColor ?? Color.alphaBlend(AppColors.edgeShade, color);
    return SizedBox(
      height: height,
      child: ChunkyButton(
        color: color,
        edgeColor: edge,
        depth: _depth,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onPressed: onPressed,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.white, size: fontSize + 4),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    shadows: [Shadow(color: edge, offset: const Offset(0, 2))],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
