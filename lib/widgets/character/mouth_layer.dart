import 'package:flutter/material.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';

/// Dibuja una boca en el lienzo del personaje (512x768).
///
/// Misma técnica que los ojos: [BlendMode.modulate] multiplica el dibujo
/// por [color], así que lo blanco toma el color y lo negro sigue negro. Solo
/// se tiñe la capa que tiene el blanco; el resto se dibuja como está.
///
/// [color] es el color elegido, o el tono de piel si no eligió ninguno.
class MouthLayer extends StatelessWidget {
  const MouthLayer({super.key, required this.style, required this.color});

  final MouthStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final layer in style.layers)
          CharacterLayer(layer.asset, tint: layer.tinted ? color : null),
      ],
    );
  }
}
