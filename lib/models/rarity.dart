import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Rareza de un cosmético. Decide qué tan seguido sale en los cofres: entre
/// los cosméticos que el jugador todavía no tiene, cada uno pesa su
/// [weight]; a más rareza, menos peso.
///
/// El [level] (1 a 5) sirve para ordenar la Tienda por rareza.
enum Rarity {
  common(1, 'Común', 50, AppColors.rarityCommon),
  uncommon(2, 'Poco común', 28, AppColors.rarityUncommon),
  rare(3, 'Raro', 14, AppColors.rarityRare),
  epic(4, 'Épico', 6, AppColors.rarityEpic),
  legendary(5, 'Legendario', 2, AppColors.rarityLegendary);

  const Rarity(this.level, this.label, this.weight, this.color);

  final int level;
  final String label;

  /// Peso en el sorteo de cosméticos de los cofres.
  final int weight;
  final Color color;
}
