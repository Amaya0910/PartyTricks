import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Botón "Continuar con Google" de las tarjetas de acceso.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  /// Null mientras carga.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(42),
        foregroundColor: AppColors.authText,
        side: const BorderSide(color: AppColors.authField, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // El logo de Google es una marca: se usa un ícono genérico.
      icon: const Icon(Icons.account_circle, color: AppColors.authAccent),
      label: const Text(
        'Continuar con Google',
        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
    );
  }
}
