import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Hoja blanca pegada abajo de la pantalla de la foto, con el borde azul de
/// los diálogos del juego. Encima queda la escena: el personaje o el visor.
class FacePhotoSheet extends StatelessWidget {
  const FacePhotoSheet({
    super.key,
    required this.title,
    required this.message,
    required this.child,
    this.trailing,
  });

  final String title;
  final String message;

  /// Lo que va a la derecha del título.
  final Widget? trailing;
  final Widget child;

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_radius),
        ),
        border: Border.all(color: AppColors.authAccent, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pillShadow,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.authHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
