import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';

/// Sortea el premio de un cofre según sus probabilidades.
class ChestRoller {
  const ChestRoller();

  ChestOutcome roll(ChestOdds odds, RandomSource random) {
    final roll = random.nextInt(1, 100);
    var limit = odds.cosmetic;
    if (roll <= limit) return ChestOutcome.cosmetic;
    limit += odds.nothing;
    if (roll <= limit) return ChestOutcome.nothing;
    limit += odds.coins;
    if (roll <= limit) return ChestOutcome.coins;
    return ChestOutcome.dice;
  }
}