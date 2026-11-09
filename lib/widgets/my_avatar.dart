import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/accessory_controller.dart';
import 'package:party_tricks/controllers/hair_controller.dart';
import 'package:party_tricks/controllers/avatar_controller.dart';
import 'package:party_tricks/controllers/eyes_controller.dart';
import 'package:party_tricks/controllers/face_photo_controller.dart';
import 'package:party_tricks/controllers/mouth_controller.dart';
import 'package:party_tricks/controllers/skin_tone_controller.dart';
import 'package:party_tricks/widgets/character/head_avatar.dart';

/// La foto de perfil del jugador con la sesión iniciada: su cabeza tal como
/// la tiene puesta en el Vestuario, sobre el color que eligió en Ajustes.
class MyAvatar extends ConsumerWidget {
  const MyAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HeadAvatar(
      skinTone: ref.watch(skinToneProvider),
      eyes: ref.watch(eyeStyleProvider),
      eyeColor: ref.watch(eyeColorProvider),
      mouth: ref.watch(mouthStyleProvider),
      mouthColor: ref.watch(mouthColorProvider),
      accessory: ref.watch(accessoryProvider),
      hair: ref.watch(hairProvider),
      hairColor: ref.watch(hairColorProvider),
      avatarColor: ref.watch(avatarColorProvider),
      facePhoto: ref.watch(facePhotoProvider),
      size: size,
    );
  }
}
