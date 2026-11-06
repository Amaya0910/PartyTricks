import 'package:flutter/material.dart';
import 'package:party_tricks/models/eye_style.dart';

/// Dibuja unos ojos en el lienzo del personaje (512x768).
///
/// Misma técnica que el tono de piel: [BlendMode.modulate] multiplica el
/// dibujo por [color], así que lo blanco toma el color y lo negro sigue
/// negro. Solo se tiñe la capa de línea (o el PNG único); el relleno queda
/// como está dibujado.
class EyesLayer extends StatelessWidget {
  const EyesLayer({
    super.key,
    required this.style,
    required this.color,
    required this.size,
  });

  final EyeStyle style;
  final Color color;

  /// Tamaño del lienzo en el que se dibujan las capas.
  final Size size;

  @override
  Widget build(BuildContext context) {
    final fill = style.fillAsset;
    return Stack(
      children: [
        if (fill != null) _image(fill),
        ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.modulate),
          child: _image(style.tintedAsset),
        ),
      ],
    );
  }

  Widget _image(String asset) => Image.asset(
    asset,
    width: size.width,
    height: size.height,
    filterQuality: FilterQuality.medium,
    // Si falta una capa (arte en progreso), no se dibuja en vez de fallar.
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}
