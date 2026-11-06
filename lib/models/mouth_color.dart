import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Colores de boca. En el perfil se guarda solo la posición
/// (0 a [count] - 1).
///
/// Son los mismos 20 de los ojos ([AppColors.eyeColors]), pero la posición
/// 0 es "sin color": lo blanco de la boca toma el tono de piel del
/// personaje (por eso [colorOf] devuelve null y quien dibuja usa la piel).
abstract final class MouthColor {
  static int get count => AppColors.eyeColors.length;

  /// Sin color: la boca toma el tono de piel.
  static const int noColorIndex = 0;

  /// Color de quien todavía no ha elegido uno.
  static const int defaultIndex = noColorIndex;

  /// Lleva cualquier número a una posición válida (por si en Firestore
  /// queda un valor viejo o fuera de rango).
  static int clamp(int index) => index.clamp(0, count - 1);

  /// Color elegido, o null si es "sin color".
  static Color? colorOf(int index) {
    final safe = clamp(index);
    return safe == noColorIndex ? null : AppColors.eyeColors[safe];
  }

  /// Los colores para la línea del Vestuario: en la posición 0 se muestra
  /// el tono de piel, que es lo que toma la boca sin color.
  static List<Color> swatches(Color skinTone) => [
    skinTone,
    ...AppColors.eyeColors.skip(1),
  ];
}
