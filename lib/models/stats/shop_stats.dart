import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/stats/stats_map.dart';

/// Tienda de Tricks: cofres abiertos, diamantes gastados y premios.
///
/// Se guarda en la misma transacción de la compra (ver
/// `FirestoreStatsDocument.chestIncrements`). Las claves de Firestore
/// están aquí para que el modelo y esa escritura no se separen.
class ShopStats {
  const ShopStats({
    this.chestsOpened = const {},
    this.diamondsSpent = 0,
    this.cosmeticPrizes = 0,
    this.emptyPrizes = 0,
    this.coinPrizes = 0,
    this.dicePrizes = 0,
    this.coinsFromChests = 0,
  });

  static const chestsOpenedKey = 'chestsOpened';
  static const diamondsSpentKey = 'diamondsSpent';
  static const coinsFromChestsKey = 'coinsFromChests';

  /// Clave del contador de cada premio.
  static String prizeKey(ChestOutcome outcome) => switch (outcome) {
    ChestOutcome.cosmetic => 'cosmeticPrizes',
    ChestOutcome.nothing => 'emptyPrizes',
    ChestOutcome.coins => 'coinPrizes',
    ChestOutcome.dice => 'dicePrizes',
  };

  /// Cofres abiertos por tipo (`ChestType.name`).
  final Map<String, int> chestsOpened;
  final int diamondsSpent;

  /// Veces que salió cada premio.
  final int cosmeticPrizes;
  final int emptyPrizes;
  final int coinPrizes;
  final int dicePrizes;

  /// Monedas ganadas con el premio "100 Monedas".
  final int coinsFromChests;

  int opened(ChestType chest) => chestsOpened[chest.name] ?? 0;

  int get totalChests => chestsOpened.values.fold(0, (a, b) => a + b);

  factory ShopStats.fromMap(Map<String, dynamic> map) {
    int read(String key) => StatsMap.readInt(map, key);
    return ShopStats(
      chestsOpened: StatsMap.readIntMap(map, chestsOpenedKey),
      diamondsSpent: read(diamondsSpentKey),
      cosmeticPrizes: read(prizeKey(ChestOutcome.cosmetic)),
      emptyPrizes: read(prizeKey(ChestOutcome.nothing)),
      coinPrizes: read(prizeKey(ChestOutcome.coins)),
      dicePrizes: read(prizeKey(ChestOutcome.dice)),
      coinsFromChests: read(coinsFromChestsKey),
    );
  }

  Map<String, dynamic> toMap() => {
    chestsOpenedKey: chestsOpened,
    diamondsSpentKey: diamondsSpent,
    prizeKey(ChestOutcome.cosmetic): cosmeticPrizes,
    prizeKey(ChestOutcome.nothing): emptyPrizes,
    prizeKey(ChestOutcome.coins): coinPrizes,
    prizeKey(ChestOutcome.dice): dicePrizes,
    coinsFromChestsKey: coinsFromChests,
  };
}
