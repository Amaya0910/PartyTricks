import 'package:party_tricks/services/game_engine/game_state.dart';

/// Diamantes que se entregan al final (diseno_juego.md, sección 10).
enum FinalAward { minigames, worstLuck, richest, topBuyer }

/// Resultado de la partida después de entregar los diamantes finales.
class FinalResult {
  const FinalResult({
    required this.awards,
    required this.diamonds,
    required this.winnerIds,
    required this.places,
  });

  /// Quiénes ganaron cada diamante final. Si hay empate, todos lo reciben.
  final Map<FinalAward, List<String>> awards;

  /// Diamantes totales de cada jugador, ya con los finales sumados.
  final Map<String, int> diamonds;

  /// Los que tienen más diamantes. Si hay empate, todos ganan.
  final List<String> winnerIds;

  /// Puesto de cada jugador (1, 2, 3...). Los empatados comparten puesto.
  final Map<String, int> places;
}

/// Entrega los diamantes finales y decide quién ganó.
class AwardCalculator {
  const AwardCalculator();

  FinalResult calculate(GameState state) {
    final players = state.players.values.toList();
    final awards = {
      FinalAward.minigames: _best(players, (p) => p.minigamesWon),
      FinalAward.worstLuck: _best(players, (p) => p.negativeTiles),
      FinalAward.richest: _best(players, (p) => p.coins),
      FinalAward.topBuyer: _best(players, (p) => p.purchases),
    };

    final diamonds = {for (final p in players) p.id: p.diamonds};
    for (final winners in awards.values) {
      for (final id in winners) {
        diamonds[id] = diamonds[id]! + 1;
      }
    }

    final mostDiamonds = diamonds.values.reduce((a, b) => a > b ? a : b);
    final places = {
      for (final id in diamonds.keys)
        id: 1 + diamonds.values.where((d) => d > diamonds[id]!).length,
    };

    return FinalResult(
      awards: awards,
      diamonds: diamonds,
      winnerIds: [
        for (final entry in diamonds.entries)
          if (entry.value == mostDiamonds) entry.key,
      ],
      places: places,
    );
  }

  /// Ids de los jugadores con el valor más alto. Si nadie tiene nada
  /// (por ejemplo, nadie compró), nadie se lleva el diamante.
  List<String> _best(
    List<PlayerState> players,
    int Function(PlayerState) value,
  ) {
    final max = players.map(value).reduce((a, b) => a > b ? a : b);
    if (max == 0) return [];
    return [
      for (final p in players)
        if (value(p) == max) p.id,
    ];
  }
}
