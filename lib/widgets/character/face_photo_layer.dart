import 'package:flutter/material.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/character/head_shape.dart';

/// Dibuja la foto de la cara del jugador en el lienzo de 512x768. Cubre toda
/// la cabeza, en lugar de los ojos y la boca: se recorta con su forma y el
/// contorno de la cabeza se vuelve a dibujar encima.
class FacePhotoLayer extends StatelessWidget {
  const FacePhotoLayer({super.key, required this.photo});

  final FacePhoto photo;

  static const String _outline = 'assets/images/personaje/linea_cabeza.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kCharacterCanvas,
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: HeadShape.zone,
            child: ClipPath(
              clipper: const HeadClipper(),
              child: Image.memory(
                photo.bytes,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                // Evita el parpadeo cuando cambia la foto.
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          const CharacterLayer(_outline),
        ],
      ),
    );
  }
}
