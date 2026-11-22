import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/eyes_controller.dart';
import 'package:party_tricks/controllers/hair_controller.dart';
import 'package:party_tricks/models/hair_color.dart';
import 'package:party_tricks/controllers/mouth_controller.dart';
import 'package:party_tricks/controllers/skin_tone_controller.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/widgets/accessory_picker.dart';
import 'package:party_tricks/widgets/eyes_picker.dart';
import 'package:party_tricks/widgets/hair_picker.dart';
import 'package:party_tricks/widgets/mouth_picker.dart';
import 'package:party_tricks/widgets/pants_picker.dart';
import 'package:party_tricks/widgets/shirt_picker.dart';

/// El dibujo de un cosmético (ojos, boca, camisa, pantalón, cabello o accesorio) con el color y
/// el tono de piel que tiene elegidos el jugador. Lo usan la Tienda, los
/// cofres y la ventana de compra.
class CosmeticPreview extends ConsumerWidget {
  const CosmeticPreview(this.cosmetic, {super.key});

  final ShopCosmetic cosmetic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = SkinTone.colorOf(ref.watch(skinToneProvider));
    return switch (cosmetic) {
      EyeStyle eyes => EyesThumbnail(
        style: eyes,
        color: EyeColor.colorOf(ref.watch(eyeColorProvider)),
      ),
      // Sin color, lo blanco de la boca toma el tono de piel.
      MouthStyle mouth => MouthThumbnail(
        style: mouth,
        color: MouthColor.colorOf(ref.watch(mouthColorProvider)) ?? skin,
      ),
      ShirtStyle shirt => ShirtThumbnail(style: shirt, skin: skin),
      PantsStyle pants => PantsThumbnail(style: pants, skin: skin),
      HairStyle hair => HairThumbnail(
        style: hair,
        skin: skin,
        color: HairColor.colorOf(ref.watch(hairColorProvider)),
      ),
      AccessoryStyle accessory => AccessoryThumbnail(
        style: accessory,
        skin: skin,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
