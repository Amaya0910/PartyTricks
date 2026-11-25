import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Tarjeta blanca con borde azul y sombra dura, la base de los paneles de la
/// partida (resultados, panel del tablero, avisos). Solo dibuja.
class PartyPanel extends StatelessWidget {
  const PartyPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.boardPanel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.authAccent, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.headerBorder,
            blurRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
