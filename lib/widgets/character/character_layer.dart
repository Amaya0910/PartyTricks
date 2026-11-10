import 'package:flutter/material.dart';

/// Espacio vacío arriba del lienzo, para el cabello y los sombreros. Todo lo
/// que está medido en píxeles del lienzo sube de la altura original (768)
/// con este margen.
const double kCharacterTopMargin = 200;

/// Tamaño del lienzo en el que están dibujadas todas las capas.
const Size kCharacterCanvas = Size(512, 768 + kCharacterTopMargin);

/// Un PNG del personaje, del tamaño del lienzo.
///
/// [tint] multiplica el dibujo ([BlendMode.modulate]): lo blanco toma ese
/// color y lo negro sigue negro. Se aplica al pintar la imagen y no con
/// `ColorFiltered`, que abre una capa aparte en cada cuadro.
class CharacterLayer extends StatelessWidget {
  const CharacterLayer(this.asset, {super.key, this.tint});

  final String asset;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: kCharacterCanvas.width,
      height: kCharacterCanvas.height,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.modulate,
      filterQuality: FilterQuality.medium,
      // Si falta una capa (arte en progreso), no se dibuja en vez de fallar.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
