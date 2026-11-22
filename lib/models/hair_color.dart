import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Colores del cabello blanco. En el perfil se guarda solo la posición
/// (0 a [count] - 1). Son los mismos colores que los de los ojos
/// ([AppColors.eyeColors]) y todos están desbloqueados.
///
/// El color se aplica con [BlendMode.modulate]: lo blanco del cabello toma el
/// color. La posición 0 es blanco: deja el cabello como está dibujado.
abstract final class HairColor {
  static int get count => AppColors.eyeColors.length;

  /// Color de quien todavía no ha elegido uno (el blanco original).
  static const int defaultIndex = 0;

  /// Lleva cualquier número a una posición válida.
  static int clamp(int index) => index.clamp(0, count - 1);

  static Color colorOf(int index) => AppColors.eyeColors[clamp(index)];
}
