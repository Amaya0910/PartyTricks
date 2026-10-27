import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Foto de perfil redonda. Si no hay foto (o no carga), muestra un ícono.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.photoUrl, this.size = 48});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.blueLight,
          border: Border.all(color: AppColors.white, width: 2),
        ),
        child: ClipOval(
          child: url == null || url.isEmpty
              ? const _Fallback()
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _Fallback(),
                ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      child: Icon(Icons.person, color: AppColors.blueStrong),
    );
  }
}
