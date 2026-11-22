import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';

/// Si un efecto especial ayuda, estorba o depende de la suerte.
enum EffectKind { good, bad, neutral }

/// Efecto que deja una casilla especial para el siguiente turno del jugador
/// (diseno_juego.md, sección 6.1). Se aplica al lanzar el dado.
///
/// [weight] es qué tan seguido sale: los más fuertes salen menos. Los nombres
/// de los primeros cinco no se cambian porque se guardan en la partida.
enum PendingEffect {
  die3(EffectKind.bad, 8, 'Dado de 3', 'Tu siguiente dado solo llega hasta 3.'),
  die12(EffectKind.good, 8, 'Dado de 12', 'Tu siguiente dado llega hasta 12.'),
  backToStart(
    EffectKind.neutral,
    8,
    'Regreso al inicio',
    'Vuelves a la salida antes de lanzar.',
  ),
  loseCoins(
    EffectKind.bad,
    10,
    'Se esfuman las monedas',
    'Pierdes monedas antes de lanzar.',
  ),
  gainCoins(
    EffectKind.good,
    10,
    'Lluvia de monedas',
    'Ganas monedas antes de lanzar.',
  ),
  boost(
    EffectKind.good,
    10,
    'Viento a favor',
    'Avanzas 3 casillas más en tu siguiente tirada.',
  ),
  freeShield(
    EffectKind.good,
    8,
    'Escudo de regalo',
    'Recibes un escudo para tu mochila.',
  ),
  freeItem(
    EffectKind.good,
    8,
    'Ítem sorpresa',
    'Recibes un ítem al azar para tu mochila.',
  ),
  diamondGift(
    EffectKind.good,
    3,
    'Diamante de regalo',
    'Ganas un diamante antes de lanzar.',
  ),
  coinSwap(
    EffectKind.neutral,
    6,
    'Cambio de monedas',
    'Cambias tus monedas con las de un rival al azar.',
  ),
  die2(EffectKind.bad, 9, 'Dado de 2', 'Tu siguiente dado solo llega hasta 2.'),
  skipTurn(
    EffectKind.bad,
    6,
    'Pierdes el turno',
    'No juegas tu siguiente turno.',
  ),
  loseItem(
    EffectKind.bad,
    8,
    'Se te cae un ítem',
    'Pierdes un ítem de tu mochila al azar.',
  ),
  payEveryone(
    EffectKind.bad,
    8,
    'Paga la cuenta de la fiesta',
    'Le das monedas a cada rival.',
  );

  const PendingEffect(this.kind, this.weight, this.title, this.description);

  final EffectKind kind;
  final int weight;
  final String title;
  final String description;

  /// Suma de los pesos, para sortear uno.
  static final int totalWeight = values.fold(0, (sum, e) => sum + e.weight);

  /// El efecto que sale con [roll] (de 1 a [totalWeight]).
  static PendingEffect forRoll(int roll) {
    var left = roll;
    for (final effect in values) {
      left -= effect.weight;
      if (left <= 0) return effect;
    }
    return values.last;
  }
}

/// Lo que le pasa a un jugador al caer en una casilla.
class TileOutcome {
  const TileOutcome({this.coinDelta = 0, this.pendingEffect});

  /// Monedas que gana (positivo) o pierde (negativo) en este momento.
  final int coinDelta;

  /// Efecto guardado para su siguiente turno, si cayó en una especial.
  final PendingEffect? pendingEffect;
}

/// Efecto de cada tipo de casilla (diseno_juego.md, sección 6.1).
///
/// Las cantidades son provisionales; en el diseño están por definir.
class TileEffects {
  const TileEffects({
    this.positiveCoins = 3,
    this.negativeCoins = 3,
    this.specialCoins = 5,
    this.partyBillCoins = 2,
  });

  final int positiveCoins;
  final int negativeCoins;

  /// Monedas que se ganan o pierden con los efectos especiales de monedas.
  final int specialCoins;

  /// Monedas que paga a cada rival el efecto "Paga la cuenta de la fiesta".
  final int partyBillCoins;

  TileOutcome resolve(TileType type, RandomSource random) {
    return switch (type) {
      TileType.positive => TileOutcome(coinDelta: positiveCoins),
      TileType.negative => TileOutcome(coinDelta: -negativeCoins),
      TileType.special => TileOutcome(pendingEffect: _randomEffect(random)),
      TileType.start || TileType.shop => const TileOutcome(),
    };
  }

  PendingEffect _randomEffect(RandomSource random) {
    return PendingEffect.forRoll(random.nextInt(1, PendingEffect.totalWeight));
  }
}
