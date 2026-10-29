import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/experience_calculator.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';

/// Nombre de cada diamante final para mostrarlo (diseno_juego.md, sección 10).
extension FinalAwardLabel on FinalAward {
  String get label => switch (this) {
    FinalAward.minigames => 'Más minijuegos ganados',
    FinalAward.worstLuck => 'Peor suerte',
    FinalAward.richest => 'Más monedas',
    FinalAward.topBuyer => 'Más comprador',
  };
}

/// Cómo terminó un jugador.
class PlayerResult {
  const PlayerResult({
    required this.player,
    required this.place,
    required this.diamonds,
    required this.experience,
    required this.awards,
  });

  /// El estado con el que terminó: monedas y contadores de la partida.
  final PlayerState player;

  /// 1, 2, 3... Los empatados comparten puesto.
  final int place;

  /// Diamantes totales, ya con los diamantes finales sumados.
  final int diamonds;

  /// XP que gana por la partida.
  final int experience;

  /// Diamantes finales que ganó.
  final List<FinalAward> awards;

  String get id => player.id;
  String get username => player.username;
  int get coins => player.coins;
}

/// Resultado completo de una partida terminada.
class MatchResults {
  const MatchResults({
    required this.ranking,
    required this.winnerIds,
    required this.awards,
    required this.rounds,
  });

  /// Todos los jugadores, del primero al último.
  final List<PlayerResult> ranking;

  /// Los que tienen más diamantes. Si hay empate, todos ganan.
  final List<String> winnerIds;

  /// Quiénes ganaron cada diamante final.
  final Map<FinalAward, List<String>> awards;

  /// Rondas jugadas.
  final int rounds;

  bool get isTie => winnerIds.length > 1;

  PlayerResult? of(String playerId) {
    for (final result in ranking) {
      if (result.id == playerId) return result;
    }
    return null;
  }
}

/// Arma el [MatchResults] con los cálculos que ya tiene el motor: los
/// diamantes finales ([AwardCalculator]) y la XP ([ExperienceCalculator]).
class MatchResultsBuilder {
  const MatchResultsBuilder({
    this.awards = const AwardCalculator(),
    this.experience = const ExperienceCalculator(),
  });

  final AwardCalculator awards;
  final ExperienceCalculator experience;

  MatchResults build(GameState game) {
    final result = awards.calculate(game);
    final players = game.players.length;
    final ranking = [
      for (final player in game.players.values)
        PlayerResult(
          player: player,
          place: result.places[player.id]!,
          diamonds: result.diamonds[player.id]!,
          experience: experience.xpForMatch(
            place: result.places[player.id]!,
            players: players,
            rounds: game.round,
          ),
          awards: [
            for (final entry in result.awards.entries)
              if (entry.value.contains(player.id)) entry.key,
          ],
        ),
    ];
    // Por puesto; entre empatados, el de más monedas y luego por nombre.
    ranking.sort((a, b) {
      final byPlace = a.place.compareTo(b.place);
      if (byPlace != 0) return byPlace;
      final byCoins = b.coins.compareTo(a.coins);
      if (byCoins != 0) return byCoins;
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });
    return MatchResults(
      ranking: ranking,
      winnerIds: result.winnerIds,
      awards: result.awards,
      rounds: game.round,
    );
  }
}
