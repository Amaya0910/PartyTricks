import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Tonos de piel del personaje. En el perfil se guarda solo la posición
/// (0 a [count] - 1); el color sale de [AppColors.skinTones].
abstract final class SkinTone {
  static int get count => AppColors.skinTones.length;

  /// Tono de quien todavía no ha elegido uno.
  static const int defaultIndex = 4;

  /// Lleva cualquier número a una posición válida (por si en Firestore
  /// queda un valor viejo o fuera de rango).
  static int clamp(int index) => index.clamp(0, count - 1);

  static Color colorOf(int index) => AppColors.skinTones[clamp(index)];
}
