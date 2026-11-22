import 'package:flutter/material.dart';
import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/head_avatar.dart';

/// Foto de perfil redonda: la cabeza del personaje de [profile] sobre su
/// color de fondo. Si todavía no hay perfil, muestra un ícono.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.profile, this.size = 48});

  final PublicProfile? profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    if (profile == null) {
      return SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.blueLight,
            border: Border.all(color: AppColors.white, width: 2),
          ),
          child: const ClipOval(
            child: FittedBox(
              child: Icon(Icons.person, color: AppColors.blueStrong),
            ),
          ),
        ),
      );
    }
    return HeadAvatar(
      skinTone: profile.skinTone,
      eyes: profile.eyes,
      eyeColor: profile.eyeColor,
      mouth: profile.mouth,
      mouthColor: profile.mouthColor,
      accessory: profile.accessory,
      hair: profile.hair,
      hairColor: profile.hairColor,
      avatarColor: profile.avatarColor,
      facePhoto: profile.facePhoto,
      size: size,
    );
  }
}
