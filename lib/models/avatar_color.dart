import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Color de fondo de la foto de perfil (la cabeza del personaje). Se elige
/// en Ajustes > Preferencias. En el perfil se guarda solo la posición
/// (0 a [count] - 1); el color sale de [AppColors.avatarColors].
abstract final class AvatarColor {
  static int get count => AppColors.avatarColors.length;

  /// Color de quien todavía no ha elegido uno.
  static const int defaultIndex = 0;

  /// Lleva cualquier número a una posición válida (por si en Firestore
  /// queda un valor viejo o fuera de rango).
  static int clamp(int index) => index.clamp(0, count - 1);

  static Color colorOf(int index) => AppColors.avatarColors[clamp(index)];
}
