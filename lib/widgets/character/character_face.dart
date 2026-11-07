import 'package:flutter/material.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/widgets/character/eyes_layer.dart';
import 'package:party_tricks/widgets/character/face_photo_layer.dart';
import 'package:party_tricks/widgets/character/mouth_layer.dart';

/// La cara del personaje en el lienzo: la foto del jugador si tiene una o,
/// si no, sus ojos y su boca.
class CharacterFace extends StatelessWidget {
  const CharacterFace({
    super.key,
    required this.eyes,
    required this.eyeColor,
    required this.mouth,
    required this.mouthColor,
    this.photo,
  });

  final EyeStyle eyes;
  final Color eyeColor;
  final MouthStyle mouth;

  /// El color elegido, o el tono de piel si no eligió ninguno.
  final Color mouthColor;
  final FacePhoto? photo;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    if (photo != null) return FacePhotoLayer(photo: photo);
    return Stack(
      children: [
        EyesLayer(style: eyes, color: eyeColor),
        MouthLayer(style: mouth, color: mouthColor),
      ],
    );
  }
}
