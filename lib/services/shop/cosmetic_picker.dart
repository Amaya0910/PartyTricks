import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';

/// Un cosmético que puede salir de un cofre y qué tan probable es.
class CosmeticChance {
  const CosmeticChance({
    this.eyes,
    this.mouth,
    required this.weight,
    required this.percent,
  }) : assert((eyes == null) != (mouth == null), 'Es unos ojos o una boca');

  final EyeStyle? eyes;
  final MouthStyle? mouth;

  /// Peso en el sorteo (el de su rareza).
  final int weight;

  /// Probabilidad de 0 a 100 de que sea este, dado que sale un cosmético.
  final double percent;

  Rarity get rarity => eyes?.rarity ?? mouth!.rarity;
  String get title => eyes?.title ?? mouth!.title;
}

/// Elige el cosmético que sale de un cofre.
///
/// Solo entran los que se venden en la Tienda (no los gratis) y que el
/// jugador todavía no tiene. Cada uno pesa lo que dice su rareza
/// (`Rarity.weight`): los comunes salen más seguido que los legendarios.
class CosmeticPicker {
  const CosmeticPicker();

  /// Los cosméticos que todavía pueden salir, en el orden del catálogo, con
  /// su probabilidad. Vacío si ya los tiene todos.
  List<CosmeticChance> chances({
    required Set<int> ownedEyes,
    required Set<int> ownedMouths,
  }) {
    final candidates = <({EyeStyle? eyes, MouthStyle? mouth, int weight})>[
      for (final eyes in EyeStyle.values)
        if (!eyes.isFree && !ownedEyes.contains(eyes.number))
          (eyes: eyes, mouth: null, weight: eyes.rarity.weight),
      for (final mouth in MouthStyle.values)
        if (!mouth.isFree && !ownedMouths.contains(mouth.number))
          (eyes: null, mouth: mouth, weight: mouth.rarity.weight),
    ];
    final total = candidates.fold<int>(0, (sum, c) => sum + c.weight);
    return [
      for (final c in candidates)
        CosmeticChance(
          eyes: c.eyes,
          mouth: c.mouth,
          weight: c.weight,
          percent: c.weight * 100 / total,
        ),
    ];
  }

  /// El premio con el cosmético elegido, o null si ya tiene todos.
  ChestPrize? pick({
    required Set<int> ownedEyes,
    required Set<int> ownedMouths,
    required RandomSource random,
  }) {
    final candidates = chances(ownedEyes: ownedEyes, ownedMouths: ownedMouths);
    if (candidates.isEmpty) return null;

    final total = candidates.fold<int>(0, (sum, c) => sum + c.weight);
    var roll = random.nextInt(1, total);
    for (final candidate in candidates) {
      roll -= candidate.weight;
      if (roll <= 0) {
        return ChestPrize(
          ChestOutcome.cosmetic,
          eyes: candidate.eyes,
          mouth: candidate.mouth,
        );
      }
    }
    return null;
  }
}
