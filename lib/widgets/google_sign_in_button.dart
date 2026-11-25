import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/chunky_button.dart';

/// Botón "Continuar con Google" de las tarjetas de acceso.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  /// Null mientras carga.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ChunkyButton(
        color: AppColors.white,
        edgeColor: AppColors.authField,
        borderColor: AppColors.authField,
        radius: 14,
        depth: 4,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: const Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // El logo de Google es una marca: se usa un ícono genérico.
                Icon(Icons.account_circle, color: AppColors.authAccent),
                SizedBox(width: 8),
                Text(
                  'Continuar con Google',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    color: AppColors.authText,
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
