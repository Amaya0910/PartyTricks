import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';

/// Un cosmético que puede salir de un cofre y qué tan probable es.
class CosmeticChance {
  const CosmeticChance({
    required this.cosmetic,
    required this.weight,
    required this.percent,
  });

  final ShopCosmetic cosmetic;

  /// Peso en el sorteo (el de su rareza).
  final int weight;

  /// Probabilidad de 0 a 100 de que sea este, dado que sale un cosmético.
  final double percent;

  EyeStyle? get eyes => cosmetic is EyeStyle ? cosmetic as EyeStyle : null;
  MouthStyle? get mouth =>
      cosmetic is MouthStyle ? cosmetic as MouthStyle : null;
  ShirtStyle? get shirt =>
      cosmetic is ShirtStyle ? cosmetic as ShirtStyle : null;
  PantsStyle? get pants =>
      cosmetic is PantsStyle ? cosmetic as PantsStyle : null;
  HairStyle? get hair => cosmetic is HairStyle ? cosmetic as HairStyle : null;
  AccessoryStyle? get accessory =>
      cosmetic is AccessoryStyle ? cosmetic as AccessoryStyle : null;

  Rarity get rarity => cosmetic.rarity;
  String get title => cosmetic.title;
}

/// Elige el cosmético que sale de un cofre.
///
/// Solo entran los que se venden en la Tienda (no los gratis) y que el
/// jugador todavía no tiene: ojos, bocas, camisas y accesorios. Cada uno pesa
/// lo que dice su rareza (`Rarity.weight`): los comunes salen más seguido que
/// los legendarios.
class CosmeticPicker {
  const CosmeticPicker();

  /// Los cosméticos que todavía pueden salir, en el orden del catálogo
  /// (ojos, bocas, camisas, pantalones, cabellos y accesorios), con su probabilidad. Vacío si ya
  /// los tiene todos.
  List<CosmeticChance> chances({
    required Set<int> ownedEyes,
    required Set<int> ownedMouths,
    Set<int> ownedShirts = const {},
    Set<int> ownedPants = const {},
    Set<int> ownedHairs = const {},
    Set<int> ownedAccessories = const {},
  }) {
    final candidates = <ShopCosmetic>[
      for (final eyes in EyeStyle.values)
        if (!eyes.isFree && !ownedEyes.contains(eyes.number)) eyes,
      for (final mouth in MouthStyle.values)
        if (!mouth.isFree && !ownedMouths.contains(mouth.number)) mouth,
      for (final shirt in ShirtStyle.values)
        if (!shirt.isFree && !ownedShirts.contains(shirt.id)) shirt,
      for (final pants in PantsStyle.values)
        if (!pants.isFree && !ownedPants.contains(pants.id)) pants,
      for (final hair in HairStyle.values)
        if (!hair.isFree && !ownedHairs.contains(hair.id)) hair,
      for (final accessory in AccessoryStyle.values)
        if (!accessory.isFree && !ownedAccessories.contains(accessory.id))
          accessory,
    ];
    final total = candidates.fold<int>(0, (sum, c) => sum + c.rarity.weight);
    return [
      for (final c in candidates)
        CosmeticChance(
          cosmetic: c,
          weight: c.rarity.weight,
          percent: c.rarity.weight * 100 / total,
        ),
    ];
  }

  /// El premio con el cosmético elegido, o null si ya tiene todos.
  ChestPrize? pick({
    required Set<int> ownedEyes,
    required Set<int> ownedMouths,
    Set<int> ownedShirts = const {},
    Set<int> ownedPants = const {},
    Set<int> ownedHairs = const {},
    Set<int> ownedAccessories = const {},
    required RandomSource random,
  }) {
    final candidates = chances(
      ownedEyes: ownedEyes,
      ownedMouths: ownedMouths,
      ownedShirts: ownedShirts,
      ownedPants: ownedPants,
      ownedHairs: ownedHairs,
      ownedAccessories: ownedAccessories,
    );
    if (candidates.isEmpty) return null;

    final total = candidates.fold<int>(0, (sum, c) => sum + c.weight);
    var roll = random.nextInt(1, total);
    for (final candidate in candidates) {
      roll -= candidate.weight;
      if (roll <= 0) return ChestPrize.cosmetic(candidate.cosmetic);
    }
    return null;
  }
}
