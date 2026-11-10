import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/accessory_controller.dart';
import 'package:party_tricks/controllers/eyes_controller.dart';
import 'package:party_tricks/controllers/face_photo_controller.dart';
import 'package:party_tricks/controllers/mouth_controller.dart';
import 'package:party_tricks/controllers/shirt_controller.dart';
import 'package:party_tricks/controllers/skin_tone_controller.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/skin_tone.dart';

/// El personaje del jugador tal como lo tiene puesto ahora (piel, ojos, boca,
/// camisa, accesorio y foto de la cara), listo para dibujar.
final characterLookProvider = Provider<CharacterLook>(
  (ref) => CharacterLook(
    skinTone: SkinTone.colorOf(ref.watch(skinToneProvider)),
    eyes: ref.watch(eyeStyleProvider),
    eyeColor: EyeColor.colorOf(ref.watch(eyeColorProvider)),
    mouth: ref.watch(mouthStyleProvider),
    mouthColor: MouthColor.colorOf(ref.watch(mouthColorProvider)),
    shirt: ref.watch(shirtProvider),
    accessory: ref.watch(accessoryProvider),
    facePhoto: ref.watch(facePhotoProvider),
  ),
);
