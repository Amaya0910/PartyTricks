import 'package:flutter/material.dart';
import 'package:party_tricks/models/mouth_style.dart';

/// Dibuja una boca en el lienzo del personaje (512x768).
///
/// Misma técnica que los ojos: [BlendMode.modulate] multiplica el dibujo
/// por [color], así que lo blanco toma el color y lo negro sigue negro. Solo
/// se tiñe la capa que tiene el blanco; el resto se dibuja como está.
///
/// [color] es el color elegido, o el tono de piel si no eligió ninguno.
class MouthLayer extends StatelessWidget {
  const MouthLayer({
    super.key,
    required this.style,
    required this.color,
    required this.size,
  });

  final MouthStyle style;
  final Color color;

  /// Tamaño del lienzo en el que se dibujan las capas.
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final layer in style.layers)
          layer.tinted
              ? ColorFiltered(
                  colorFilter: ColorFilter.mode(color, BlendMode.modulate),
                  child: _image(layer.asset),
                )
              : _image(layer.asset),
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
