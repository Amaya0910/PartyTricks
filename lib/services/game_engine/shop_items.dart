/// Ítems de las tiendas del mapa (diseno_juego.md, sección 8).
///
/// Se compran al caer en una tienda y se guardan en la mochila del jugador.
/// Los precios son provisionales; en el diseño están por definir.
enum ShopItem {
  extraDie3(
    title: 'Dado extra de 3',
    description: 'En tu turno lanzas también un dado de 3 y se suman.',
    price: 4,
    extraDieSides: 3,
  ),
  extraDie6(
    title: 'Dado extra de 6',
    description: 'En tu turno lanzas también un dado de 6 y se suman.',
    price: 6,
    extraDieSides: 6,
  ),
  extraDie9(
    title: 'Dado extra de 9',
    description: 'En tu turno lanzas también un dado de 9 y se suman.',
    price: 9,
    extraDieSides: 9,
  ),
  movementBoost(
    title: 'Impulso',
    description: 'Avanzas 3 casillas más en tu tirada.',
    price: 4,
  ),
  trap(
    title: 'Trampa',
    description:
        'La dejas en tu casilla. Al rival que pase por ahí le robas monedas.',
    price: 5,
  ),
  shield(
    title: 'Escudo',
    description: 'Anula la próxima trampa o casilla negativa. Se usa solo.',
    price: 5,
    passive: true,
  ),
  diamondBoost(
    title: 'Diamante doble',
    description:
        'La próxima vez que tomes el diamante ganas uno más. '
        'Se usa solo.',
    price: 12,
    passive: true,
  );

  const ShopItem({
    required this.title,
    required this.description,
    required this.price,
    this.extraDieSides = 0,
    this.passive = false,
  });

  final String title;
  final String description;

  /// Precio en monedas de partida.
  final int price;

  /// Caras del dado extra, o 0 si no es un dado.
  final int extraDieSides;

  /// Los pasivos no se activan: se gastan solos cuando hacen falta.
  final bool passive;

  bool get isExtraDie => extraDieSides > 0;
}

/// Cantidades de los ítems. Son provisionales, como las de `TileEffects`.
class ItemRules {
  const ItemRules({
    this.trapCoins = 5,
    this.boostSteps = 3,
    this.maxPerItem = 3,
  });

  /// Monedas que la trampa le roba al que pasa por ella.
  final int trapCoins;

  /// Casillas de más que da el impulso.
  final int boostSteps;

  /// Cuántos de cada ítem caben en la mochila.
  final int maxPerItem;
}
