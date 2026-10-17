import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';

/// Efecto que deja una casilla especial para el siguiente turno del jugador.
enum PendingEffect { die3, die12, backToStart, loseCoins, gainCoins }

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
  });

  final int positiveCoins;
  final int negativeCoins;

  /// Monedas que se ganan o pierden con los efectos especiales de monedas.
  final int specialCoins;

  TileOutcome resolve(TileType type, RandomSource random) {
    return switch (type) {
      TileType.positive => TileOutcome(coinDelta: positiveCoins),
      TileType.negative => TileOutcome(coinDelta: -negativeCoins),
      TileType.special => TileOutcome(pendingEffect: _randomEffect(random)),
      TileType.start || TileType.shop => const TileOutcome(),
    };
  }

  PendingEffect _randomEffect(RandomSource random) {
    final index = random.nextInt(0, PendingEffect.values.length - 1);
    return PendingEffect.values[index];
  }
}
