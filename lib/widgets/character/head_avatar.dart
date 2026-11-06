import 'package:flutter/material.dart';
import 'package:party_tricks/models/avatar_color.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/eyes_layer.dart';
import 'package:party_tricks/widgets/character/face_photo_layer.dart';
import 'package:party_tricks/widgets/character/mouth_layer.dart';

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
  final int avatarColor;

  /// Foto de la cara; si hay, va en lugar de los ojos y la boca.
  final FacePhoto? facePhoto;
  final double size;

  /// Zona de la cabeza en el lienzo (512x768): un cuadrado que la rodea.
  static const Rect _crop = Rect.fromLTWH(78, 40, 356, 356);

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
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            skin,
                            BlendMode.modulate,
                          ),
                          child: _layer(BodyPart.cabeza.fillAsset),
                        ),
                        _layer(BodyPart.cabeza.outlineAsset),
                        if (facePhoto != null)
                          FacePhotoLayer(
                            photo: facePhoto!,
                            size: kCharacterCanvas,
                          )
                        else ...[
                          EyesLayer(
                            style: eyes,
                            color: EyeColor.colorOf(eyeColor),
                            size: kCharacterCanvas,
                          ),
                          MouthLayer(
                            style: mouth,
                            color: MouthColor.colorOf(mouthColor) ?? skin,
                            size: kCharacterCanvas,
                          ),
                        ],
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

  Widget _layer(String asset) => Image.asset(
    asset,
    width: kCharacterCanvas.width,
    height: kCharacterCanvas.height,
    filterQuality: FilterQuality.medium,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}
