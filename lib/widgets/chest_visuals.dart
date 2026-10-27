import 'package:flutter/material.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Los dos colores de cada cofre: [card] para fondos y [strong] para
/// bordes, cabeceras y textos.
class ChestPalette {
  const ChestPalette({required this.card, required this.strong});

  final Color card;
  final Color strong;

  static ChestPalette of(ChestType chest) => switch (chest) {
    ChestType.basic => const ChestPalette(
      card: AppColors.chestBasicCard,
      strong: AppColors.chestBasicStrong,
    ),
    ChestType.party => const ChestPalette(
      card: AppColors.chestPartyCard,
      strong: AppColors.chestPartyStrong,
    ),
    ChestType.diamond => const ChestPalette(
      card: AppColors.chestDiamondCard,
      strong: AppColors.chestDiamondStrong,
    ),
  };
}

/// Dibujo del cofre. Si falta la imagen, se ve un ícono en vez de un error.
/// Dibujo del cofre. Si falta la imagen, se ve un ícono en vez de un error.
class ChestImage extends StatelessWidget {
  const ChestImage({super.key, required this.chest});

  final ChestType chest;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      chest.asset,
      fit: BoxFit.contain,
      // Las imágenes miden 1080 px pero se ven a ~100 px: se decodifican
      // más pequeñas para no gastar memoria.
      cacheWidth: 300,
      errorBuilder: (_, _, _) => Icon(
        Icons.inventory_2,
        size: 48,
        color: ChestPalette.of(chest).strong,
      ),
    );
  }
}