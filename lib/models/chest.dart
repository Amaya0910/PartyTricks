/// Premio que puede salir de un cofre.
enum ChestOutcome { cosmetic, nothing, coins, dice }

/// Monedas que da el premio "100 Monedas".
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