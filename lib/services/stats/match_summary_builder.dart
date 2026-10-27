import 'package:party_tricks/models/match_summary.dart';
import 'package:party_tricks/models/stats/award_stats.dart';
import 'package:party_tricks/models/stats/board_stats.dart';
import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';

/// Arma el [MatchSummary] de un jugador a partir de la partida terminada.
class MatchSummaryBuilder {
  const MatchSummaryBuilder({this.awards = const AwardCalculator()});

  final AwardCalculator awards;

  /// Devuelve null si la partida no ha terminado o si el jugador no estaba.
  MatchSummary? build({
    required String matchId,
    required GameState game,
    required String playerId,
    bool isHost = false,
    bool isPublic = false,
    Duration playingTime = Duration.zero,
    Duration minigameTime = Duration.zero,
  }) {
    final player = game.players[playerId];
    if (game.phase != GamePhase.finished || player == null) return null;

    final result = awards.calculate(game);
    final won = result.winnerIds.contains(playerId);
    return MatchSummary(
      matchId: matchId,
      won: won,
      tied: won && result.winnerIds.length > 1,
      place: result.places[playerId] ?? game.players.length,
      diamonds: result.diamonds[playerId] ?? player.diamonds,
      coins: player.coins,
      rounds: game.round,
      isHost: isHost,
      isPublic: isPublic,
      awards: _awardsOf(playerId, result),
      board: _boardOf(player),
      minigamesWon: player.minigamesWon,
      // Hay un minijuego por ronda y la partida termina en la última.
      minigamesPlayed: game.round,
      opponents: {
        for (final other in game.players.values)
          if (other.id != playerId) other.id: other.username,
      },
      playingTime: playingTime,
      minigameTime: minigameTime,
    );
  }

  AwardStats _awardsOf(String playerId, FinalResult result) {
    int got(FinalAward award) =>
        (result.awards[award] ?? const []).contains(playerId) ? 1 : 0;
    return AwardStats(
      minigames: got(FinalAward.minigames),
      worstLuck: got(FinalAward.worstLuck),
      richest: got(FinalAward.richest),
      topBuyer: got(FinalAward.topBuyer),
    );
  }

  BoardStats _boardOf(PlayerState player) {
    return BoardStats(
      diceRolled: player.diceRolled,
      diceTotal: player.diceTotal,
      maxRolls: player.maxRolls,
      positiveTiles: player.positiveTiles,
      negativeTiles: player.negativeTiles,
      specialTiles: player.specialTiles,
      mainPathsTaken: player.mainPathsTaken,
      shortcutsTaken: player.shortcutsTaken,
      laps: player.laps,
      mapDiamonds: player.mapDiamonds,
      shopPurchases: player.purchases,
    );
  }
}
