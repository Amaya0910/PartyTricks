import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';

/// Premio que puede salir de un cofre.
enum ChestOutcome { cosmetic, nothing, coins, dice }

/// Lo que ganó el jugador al abrir un cofre. Si el premio es un cosmético,
/// trae uno solo de [eyes], [mouth], [shirt] o [accessory].
class ChestPrize {
  const ChestPrize(
    this.outcome, {
    this.eyes,
    this.mouth,
    this.shirt,
    this.accessory,
  });

  /// El premio con [cosmetic] (ojos, boca, camisa o accesorio).
  factory ChestPrize.cosmetic(ShopCosmetic cosmetic) {
    return ChestPrize(
      ChestOutcome.cosmetic,
      eyes: cosmetic is EyeStyle ? cosmetic : null,
      mouth: cosmetic is MouthStyle ? cosmetic : null,
      shirt: cosmetic is ShirtStyle ? cosmetic : null,
      accessory: cosmetic is AccessoryStyle ? cosmetic : null,
    );
  }

  final ChestOutcome outcome;
  final EyeStyle? eyes;
  final MouthStyle? mouth;
  final ShirtStyle? shirt;
  final AccessoryStyle? accessory;

  /// El cosmético ganado, sea cual sea. Null si el premio no es un cosmético.
  ShopCosmetic? get cosmetic {
    if (eyes != null) return eyes;
    if (mouth != null) return mouth;
    if (shirt != null) return shirt;
    return accessory;
  }
}

/// Monedas que da el premio "100 Monedas".
///
/// Este premio y los precios de [ChestType] también están en
/// `firestore.rules` (`isChestPurchase`, D-28): si cambian aquí, hay que
/// cambiarlos allá o las compras se rechazarán.
const int chestCoinPrize = 100;

/// Probabilidades de un cofre, en porcentaje. Deben sumar 100.
class ChestOdds {
  const ChestOdds({
    required this.cosmetic,
    required this.nothing,
    required this.coins,
    required this.dice,
  }) : assert(
         cosmetic + nothing + coins + dice == 100,
         'Las probabilidades deben sumar 100',
       );

  final int cosmetic;
  final int nothing;
  final int coins;
  final int dice;
}

/// Los cofres de la tienda. Se compran con diamantes.
///
/// Las probabilidades salen del mockup y son provisionales.
enum ChestType {
  basic(
    title: 'Cofre Básico',
    price: 50,
    odds: ChestOdds(cosmetic: 25, nothing: 5, coins: 65, dice: 5),
    asset: 'assets/images/cofres/Cofre_Basico.png',
  ),
  party(
    title: 'Cofre Party',
    price: 100,
    odds: ChestOdds(cosmetic: 40, nothing: 2, coins: 25, dice: 33),
    asset: 'assets/images/cofres/Cofre_Party.png',
  ),
  // Nombre provisional: el mockup lo repite como "Cofre Party".
  diamond(
    title: 'Cofre Diamante',
    price: 150,
    odds: ChestOdds(cosmetic: 50, nothing: 0, coins: 0, dice: 50),
    asset: 'assets/images/cofres/Cofre_Diamante.png',
  );

  const ChestType({
    required this.title,
    required this.price,
    required this.odds,
    required this.asset,
  });

  final String title;

  /// Precio en diamantes.
  final int price;
  final ChestOdds odds;

  /// Ruta de la imagen del cofre.
  final String asset;
}
