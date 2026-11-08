import 'package:flutter/material.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/avatar_color.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_head.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';

/// Foto de perfil: la cabeza del personaje (con su piel, ojos y boca) sobre
/// un fondo de color, dentro de un círculo. No se anima.
class HeadAvatar extends StatelessWidget {
  const HeadAvatar({
    super.key,
    this.skinTone = SkinTone.defaultIndex,
    this.eyes = EyeStyle.defaultStyle,
    this.eyeColor = EyeColor.defaultIndex,
    this.mouth = MouthStyle.defaultStyle,
    this.mouthColor = MouthColor.defaultIndex,
    this.accessory,
    this.avatarColor = AvatarColor.defaultIndex,
    this.facePhoto,
    this.size = 48,
  });

  /// Posiciones en SkinTone, EyeColor, MouthColor y AvatarColor.
  final int skinTone;
  final EyeStyle eyes;
  final int eyeColor;
  final MouthStyle mouth;
  final int mouthColor;

  /// Accesorio de la cabeza, si lleva.
  final AccessoryStyle? accessory;
  final int avatarColor;

  /// Foto de la cara; si hay, va en lugar de los ojos y la boca.
  final FacePhoto? facePhoto;
  final double size;

  /// Zona de la cabeza en el lienzo (512x768): un cuadrado centrado en ella
  /// (centro 256, 218). La cabeza mide unos 328 px de ancho, así que con 410
  /// ocupa cerca del 80 % del círculo y deja aire alrededor.
  static const Rect _crop = Rect.fromLTWH(51, 13, 410, 410);

  @override
  Widget build(BuildContext context) {
    final skin = SkinTone.colorOf(skinTone);
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AvatarColor.colorOf(avatarColor),
          border: Border.all(color: AppColors.white, width: 2),
        ),
        child: ClipOval(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox.fromSize(
              size: _crop.size,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -_crop.left,
                    top: -_crop.top,
                    width: kCharacterCanvas.width,
                    height: kCharacterCanvas.height,
                    child: Stack(
                      children: [
                        CharacterHead(
                          skinTone: skin,
                          eyes: eyes,
                          eyeColor: EyeColor.colorOf(eyeColor),
                          mouth: mouth,
                          mouthColor: MouthColor.colorOf(mouthColor) ?? skin,
                          photo: facePhoto,
                          accessory: accessory,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
