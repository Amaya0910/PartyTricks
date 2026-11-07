import 'package:flutter/material.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';

/// Dibuja unos ojos en el lienzo del personaje (512x768).
///
/// Misma técnica que el tono de piel: [BlendMode.modulate] multiplica el
/// dibujo por [color], así que lo blanco toma el color y lo negro sigue
/// negro. Solo se tiñe la capa de línea (o el PNG único); el relleno queda
/// como está dibujado.
class EyesLayer extends StatelessWidget {
  const EyesLayer({super.key, required this.style, required this.color});

  final EyeStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fill = style.fillAsset;
    return Stack(
      children: [
        if (fill != null) CharacterLayer(fill),
        CharacterLayer(style.tintedAsset, tint: color),
      ],
    );
  }
}
