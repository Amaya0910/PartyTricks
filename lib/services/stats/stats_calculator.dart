import 'dart:math';

import 'package:party_tricks/models/match_summary.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/match_stats.dart';
import 'package:party_tricks/models/stats/minigame_stats.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/models/stats/time_stats.dart';

/// Suma una partida terminada a las estadísticas del jugador.
///
/// No depende de Firebase: recibe y devuelve datos, así se puede probar sola.
/// Cada grupo se suma en su propio método.
class StatsCalculator {
  const StatsCalculator();

  PlayerStats applyMatch(PlayerStats stats, MatchSummary match) {
    return stats.copyWith(
      matches: _matches(stats.matches, match),
      awards: stats.awards.plus(match.awards),
      minigames: _minigames(stats.minigames, match),
      board: stats.board.plus(match.board),
      social: _social(stats.social, match),
      time: _time(stats.time, match),
    );
  }

  MatchStats _matches(MatchStats s, MatchSummary m) {
    final streak = m.won ? s.currentWinStreak + 1 : 0;
    return MatchStats(
      won: s.won + (m.won ? 1 : 0),
      lost: s.lost + (m.won ? 0 : 1),
      ties: s.ties + (m.tied ? 1 : 0),
      firstPlaces: s.firstPlaces + (m.place == 1 ? 1 : 0),
      secondPlaces: s.secondPlaces + (m.place == 2 ? 1 : 0),
      thirdPlaces: s.thirdPlaces + (m.place == 3 ? 1 : 0),
      currentWinStreak: streak,
      maxWinStreak: max(s.maxWinStreak, streak),
      maxDiamonds: max(s.maxDiamonds, m.diamonds),
      maxCoins: max(s.maxCoins, m.coins),
      totalDiamonds: s.totalDiamonds + m.diamonds,
      totalCoins: s.totalCoins + m.coins,
      hosted: s.hosted + (m.isHost ? 1 : 0),
      publicMatches: s.publicMatches + (m.isPublic ? 1 : 0),
      privateMatches: s.privateMatches + (m.isPublic ? 0 : 1),
      roundsPlayed: s.roundsPlayed + m.rounds,
      longestMatchSeconds: max(s.longestMatchSeconds, m.playingTime.inSeconds),
    );
  }

  MinigameStats _minigames(MinigameStats s, MatchSummary m) {
    final byType = Map.of(s.byType);
    for (final play in m.minigamePlays) {
      final current = byType[play.type] ?? const MinigameTypeStats();
      byType[play.type] = MinigameTypeStats(
        played: current.played + 1,
        won: current.won + (play.won ? 1 : 0),
        bestScore: max(current.bestScore, play.score),
      );
    }
    return MinigameStats(
      won: s.won + m.minigamesWon,
      lost: s.lost + m.minigamesLost,
      maxWonInMatch: max(s.maxWonInMatch, m.minigamesWon),
      bestScore: max(s.bestScore, m.bestMinigameScore),
      byType: byType,
    );
  }

  SocialStats _social(SocialStats s, MatchSummary m) {
    final playedWith = Map.of(s.playedWith);
    for (final entry in m.opponents.entries) {
      final before = playedWith[entry.key]?.matches ?? 0;
      // Se guarda el nombre más reciente, por si lo cambió.
      playedWith[entry.key] = PartnerStats(
        username: entry.value,
        matches: before + 1,
      );
    }
    return SocialStats(
      invitesSent: s.invitesSent,
      invitesAccepted: s.invitesAccepted,
      messagesSent: s.messagesSent,
      matchesWithFriends: s.matchesWithFriends + (m.playedWithFriend ? 1 : 0),
      playedWith: playedWith,
    );
  }

  TimeStats _time(TimeStats s, MatchSummary m) {
    return s.copyWith(
      secondsPlaying: s.secondsPlaying + m.playingTime.inSeconds,
      secondsInMinigames: s.secondsInMinigames + m.minigameTime.inSeconds,
    );
  }
}
