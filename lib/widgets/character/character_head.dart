import 'package:flutter/material.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/character/eyes_layer.dart';
import 'package:party_tricks/widgets/character/face_photo_layer.dart';
import 'package:party_tricks/widgets/character/mouth_layer.dart';

/// La cabeza del personaje en el lienzo, de abajo hacia arriba:
/// relleno (con la piel), boca, línea de la cabeza, accesorio y ojos.
///
/// La boca va entre el relleno y la línea porque el recorte del arte no es
/// perfecto y así el contorno tapa los bordes. La excepción es la boca con
/// la lengua afuera ([MouthStyle.overOutline]), que va encima de la línea.
///
/// Si hay [photo], va en lugar de los ojos y la boca.
class CharacterHead extends StatelessWidget {
  const CharacterHead({
    super.key,
    required this.skinTone,
    required this.eyes,
    required this.eyeColor,
    required this.mouth,
    required this.mouthColor,
    this.photo,
    this.accessory,
    this.hair,
    this.hairTint,
    this.includeBackHair = true,
    this.view = CharacterView.frente,
  });

  final Color skinTone;
  final EyeStyle eyes;
  final Color eyeColor;
  final MouthStyle mouth;

  /// El color elegido, o el tono de piel si no eligió ninguno.
  final Color mouthColor;
  final FacePhoto? photo;

  /// Accesorio de la cabeza (orejas, gorguera...), si lleva.
  final AccessoryStyle? accessory;

  /// Cabello, si lleva, y su color (null si trae el suyo). La parte de atrás
  /// va detrás de la cabeza y el resto encima de la cara.
  final HairStyle? hair;
  final Color? hairTint;

  /// Si dibuja la parte de atrás del cabello. El personaje completo la dibuja
  /// aparte, detrás del cuerpo (que no se vea delante del cuello).
  final bool includeBackHair;

  /// De lado no se usa la foto (es de frente) y de espalda no hay cara.
  final CharacterView view;

  @override
  Widget build(BuildContext context) {
    final photo = view == CharacterView.frente ? this.photo : null;
    // De espalda no se ve la cara: ni ojos, ni boca, ni foto.
    final back = view == CharacterView.espalda;
    final accessoryLayer = accessory == null
        ? null
        : CharacterLayer(
            accessory!.assetFor(view),
            tint: accessory!.skinTinted ? skinTone : null,
          );
    final mouthLayer = MouthLayer(style: mouth, color: mouthColor, view: view);
    final backHair = includeBackHair ? hair?.backAssetFor(view) : null;
    return Stack(
      children: [
        // La parte de atrás del cabello va detrás de la cabeza.
        if (backHair != null) CharacterLayer(backHair, tint: hairTint),
        CharacterLayer(BodyPart.cabeza.fillAsset, tint: skinTone),
        if (!back && photo == null && !mouth.overOutline) mouthLayer,
        CharacterLayer(BodyPart.cabeza.outlineAsset),
        if (back)
          const SizedBox.shrink()
        else if (photo != null)
          FacePhotoLayer(photo: photo)
        else ...[
          EyesLayer(style: eyes, color: eyeColor, view: view),
          if (mouth.overOutline) mouthLayer,
        ],
        // De frente y de lado el cabello va sobre la cara y los accesorios
        // sobre el cabello. De espalda es al revés: el cabello cubre toda la
        // nuca y el accesorio queda debajo.
        if (back && accessoryLayer != null) accessoryLayer,
        if (hair != null) CharacterLayer(hair!.assetFor(view), tint: hairTint),
        if (!back && accessoryLayer != null) accessoryLayer,
      ],
    );
  }
}
