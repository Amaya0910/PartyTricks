import 'package:party_tricks/models/match_summary.dart';
import 'package:party_tricks/models/stats/award_stats.dart';
import 'package:party_tricks/models/stats/board_stats.dart';
import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';

/// Arma el [MatchSummary] de un jugador a partir de la partida terminada.
class MatchSummaryBuilder {
  const MatchSummaryBuilder({this.results = const MatchResultsBuilder()});

  /// Los mismos resultados que se ven en la pantalla final.
  final MatchResultsBuilder results;

  /// Devuelve null si la partida no ha terminado o si el jugador no estaba.
  MatchSummary? build({
    required String matchId,
    required GameState game,
    required String playerId,
    bool isHost = false,
    bool isPublic = false,
    bool playedWithFriend = false,
    Duration playingTime = Duration.zero,
    Duration minigameTime = Duration.zero,
  }) {
    final player = game.players[playerId];
    if (game.phase != GamePhase.finished || player == null) return null;

    final match = results.build(game);
    final mine = match.of(playerId)!;
    final won = match.winnerIds.contains(playerId);
    return MatchSummary(
      matchId: matchId,
      won: won,
      tied: won && match.isTie,
      place: mine.place,
      diamonds: mine.diamonds,
      coins: player.coins,
      experience: mine.experience,
      rounds: game.round,
      isHost: isHost,
      isPublic: isPublic,
      awards: _awardsOf(mine),
      board: _boardOf(player),
      minigamesWon: player.minigamesWon,
      // Hay un minijuego por ronda y la partida termina en la última.
      minigamesPlayed: game.round,
      opponents: {
        for (final other in game.players.values)
          if (other.id != playerId) other.id: other.username,
      },
      playedWithFriend: playedWithFriend,
      playingTime: playingTime,
      minigameTime: minigameTime,
    );
  }

  AwardStats _awardsOf(PlayerResult result) {
    int got(FinalAward award) => result.awards.contains(award) ? 1 : 0;
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
