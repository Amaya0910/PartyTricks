import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/cosmetic_category.dart';

/// Guarda qué categoría de cosméticos está seleccionada en el Vestuario.
class WardrobeController extends Notifier<CosmeticCategory> {
  @override
  CosmeticCategory build() => CosmeticCategory.shirt;

  void select(CosmeticCategory category) => state = category;
}

final wardrobeControllerProvider =
    NotifierProvider<WardrobeController, CosmeticCategory>(
  WardrobeController.new,
);