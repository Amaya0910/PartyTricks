import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/chunky_button.dart';

/// Botón "Comprar" con relieve y el precio al lado (en monedas o diamantes).
/// Lo usan la compra de cofres y la de cosméticos. Solo dibuja.
class BuyButton extends StatelessWidget {
  const BuyButton({
    super.key,
    required this.price,
    required this.currencyIcon,
    required this.currencyColor,
    required this.face,
    required this.ink,
    required this.isLoading,
    required this.onPressed,
  });

  final int price;
  final IconData currencyIcon;
  final Color currencyColor;

  /// Color de la cara del botón.
  final Color face;

  /// Color del borde, del canto y del texto.
  final Color ink;
  final bool isLoading;

  /// Null si no se puede comprar (faltan monedas).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Relieve blanco debajo de las letras: se leen bien sobre colores claros.
    final style = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      color: ink,
      shadows: const [Shadow(color: AppColors.white, offset: Offset(0, 1.5))],
    );
    return SizedBox(
      height: 52,
      child: ChunkyButton(
        color: face,
        edgeColor: ink,
        borderColor: ink,
        radius: 24,
        depth: 5,
        padding: EdgeInsets.zero,
        onPressed: isLoading ? null : onPressed,
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ink,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Comprar', style: style),
                    const SizedBox(width: 10),
                    Icon(
                      currencyIcon,
                      size: 22,
                      color: currencyColor,
                      shadows: const [
                        Shadow(
                          color: AppColors.pillShadow,
                          offset: Offset(0, 1.5),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Text('$price', style: style),
                  ],
                ),
        ),
      ),
    );
  }
}
