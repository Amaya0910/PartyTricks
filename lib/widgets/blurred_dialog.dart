import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Desenfoque máximo del fondo detrás de un diálogo.
const double _dialogBlur = 8;

/// Abre [builder] como diálogo con el fondo desenfocado, como en el mockup.
Future<T?> showBlurredDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: AppColors.dialogBarrier,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final blur = _dialogBlur * animation.value;
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

/// Tarjeta blanca con borde azul y, opcionalmente, una cabecera azul con
/// el [title]. Solo dibuja; no sabe qué contiene.
class DialogCard extends StatelessWidget {
  const DialogCard({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  static const double _radius = 24;
  static const double _borderWidth = 3;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Padding(
      // Sube la tarjeta cuando aparece el teclado.
      padding: MediaQuery.viewInsetsOf(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.authCardBackground,
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(
                    color: AppColors.blueStrong,
                    width: _borderWidth,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.headerBorder,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_radius - _borderWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title != null) _Header(title: title),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.blueStrong,
        boxShadow: [
          BoxShadow(
            color: AppColors.headerBorder,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.progressText,
        ),
      ),
    );
  }
}