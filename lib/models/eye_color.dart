import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Colores de ojos. En el perfil se guarda solo la posición
/// (0 a [count] - 1); el color sale de [AppColors.eyeColors].
///
/// El color se aplica con [BlendMode.modulate] (la misma técnica del tono
/// de piel): lo blanco del dibujo toma el color y lo negro sigue negro.
/// Por eso la posición 0 es blanco: deja el ojo como está dibujado.
abstract final class EyeColor {
  static int get count => AppColors.eyeColors.length;

  /// Color de quien todavía no ha elegido uno (el original del dibujo).
  static const int defaultIndex = 0;

  /// Lleva cualquier número a una posición válida (por si en Firestore
  /// queda un valor viejo o fuera de rango).
  static int clamp(int index) => index.clamp(0, count - 1);

  static Color colorOf(int index) => AppColors.eyeColors[clamp(index)];
}
