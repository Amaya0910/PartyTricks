import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/match_summary.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/award_stats.dart';
import 'package:party_tricks/models/stats/board_stats.dart';
import 'package:party_tricks/models/stats/match_stats.dart';
import 'package:party_tricks/models/stats/minigame_stats.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/models/stats/time_stats.dart';
import 'package:party_tricks/services/stats/stats_calculator.dart';

void main() {
  const calculator = StatsCalculator();

  MatchSummary match({
    bool won = true,
    bool tied = false,
    int place = 1,
    int diamonds = 2,
    int coins = 30,
    int minigamesWon = 3,
    bool isHost = false,
    bool isPublic = false,
    List<MinigamePlay> plays = const [],
    Map<String, String> opponents = const {'u2': 'Beto'},
    Duration playingTime = const Duration(minutes: 12, seconds: 30),
  }) {
    return MatchSummary(
      matchId: 'sala-1',
      won: won,
      tied: tied,
      place: place,
      diamonds: diamonds,
      coins: coins,
      rounds: 5,
      isHost: isHost,
      isPublic: isPublic,
      awards: const AwardStats(minigames: 1, richest: 1),
      board: const BoardStats(diceRolled: 5, diceTotal: 17, laps: 1),
      minigamesWon: minigamesWon,
      minigamesPlayed: 5,
      minigamePlays: plays,
      opponents: opponents,
      playingTime: playingTime,
      minigameTime: const Duration(minutes: 4),
    );
  }

  group('partidas', () {
    test('una partida ganada suma resultados, podio y totales', () {
      final next = calculator.applyMatch(
        PlayerStats.empty,
        match(isHost: true, isPublic: true),
      );
      final m = next.matches;

      expect(m.won, 1);
      expect(m.lost, 0);
      expect(m.firstPlaces, 1);
      expect(m.currentWinStreak, 1);
      expect(m.maxWinStreak, 1);
      expect(m.maxDiamonds, 2);
      expect(m.maxCoins, 30);
      expect(m.totalDiamonds, 2);
      expect(m.totalCoins, 30);
      expect(m.hosted, 1);
      expect(m.publicMatches, 1);
      expect(m.privateMatches, 0);
      expect(m.roundsPlayed, 5);
      expect(m.longestMatchSeconds, 750);
    });

    test('perder corta la racha de victorias pero no la máxima', () {
      const before = PlayerStats(
        matches: MatchStats(won: 3, currentWinStreak: 3, maxWinStreak: 3),
      );

      final next = calculator.applyMatch(before, match(won: false, place: 2));

      expect(next.matches.lost, 1);
      expect(next.matches.secondPlaces, 1);
      expect(next.matches.currentWinStreak, 0);
      expect(next.matches.maxWinStreak, 3);
      expect(next.matches.privateMatches, 1);
    });

    test('un empate cuenta como ganada y como empate', () {
      final next = calculator.applyMatch(
        PlayerStats.empty,
        match(tied: true),
      );

      expect(next.matches.won, 1);
      expect(next.matches.ties, 1);
    });

    test('los máximos solo suben, nunca bajan', () {
      const before = PlayerStats(
        matches: MatchStats(maxDiamonds: 5, maxCoins: 10),
        minigames: MinigameStats(maxWonInMatch: 4, bestScore: 50),
      );

      final next = calculator.applyMatch(
        before,
        match(diamonds: 1, coins: 40, minigamesWon: 2),
      );

      expect(next.matches.maxDiamonds, 5);
      expect(next.matches.maxCoins, 40);
      expect(next.minigames.maxWonInMatch, 4);
      expect(next.minigames.bestScore, 50);
    });
  });

  test('suma premios finales y tablero', () {
    final next = calculator.applyMatch(
      const PlayerStats(
        awards: AwardStats(minigames: 2),
        board: BoardStats(diceRolled: 1, diceTotal: 6),
      ),
      match(),
    );

    expect(next.awards.minigames, 3);
    expect(next.awards.richest, 1);
    expect(next.board.diceRolled, 6);
    expect(next.board.diceTotal, 23);
    expect(next.board.laps, 1);
  });

  group('minijuegos', () {
    test('suma ganados y perdidos', () {
      final next = calculator.applyMatch(PlayerStats.empty, match());

      expect(next.minigames.won, 3);
      expect(next.minigames.lost, 2);
      expect(next.minigames.maxWonInMatch, 3);
    });

    test('suma por tipo y guarda el mejor puntaje', () {
      final next = calculator.applyMatch(
        const PlayerStats(
          minigames: MinigameStats(
            byType: {'carrera': MinigameTypeStats(played: 1, bestScore: 4)},
          ),
        ),
        match(
          plays: const [
            MinigamePlay(type: 'carrera', won: true, score: 9),
            MinigamePlay(type: 'memoria', won: false, score: 2),
          ],
        ),
      );

      final carrera = next.minigames.byType['carrera']!;
      expect(carrera.played, 2);
      expect(carrera.won, 1);
      expect(carrera.bestScore, 9);
      expect(next.minigames.byType['memoria']!.played, 1);
      expect(next.minigames.bestScore, 9);
    });
  });

  test('cuenta los compañeros de partida y guarda su nombre más reciente', () {
    final next = calculator.applyMatch(
      const PlayerStats(
        social: SocialStats(
          messagesSent: 4,
          playedWith: {'u2': PartnerStats(username: 'Betito', matches: 2)},
        ),
      ),
      match(opponents: const {'u2': 'Beto', 'u3': 'Caro'}),
    );

    expect(next.social.playedWith['u2']!.matches, 3);
    expect(next.social.playedWith['u2']!.username, 'Beto');
    expect(next.social.playedWith['u3']!.matches, 1);
    expect(next.social.messagesSent, 4);
  });

  test('suma el tiempo jugando y no toca el tiempo en la app ni la racha', () {
    const before = PlayerStats(
      time: TimeStats(
        secondsInApp: 600,
        currentStreak: 2,
        lastActiveDay: '2026-10-27',
      ),
    );

    final next = calculator.applyMatch(before, match());

    expect(next.time.secondsPlaying, 750);
    expect(next.time.secondsInMinigames, 240);
    expect(next.time.secondsInApp, 600);
    expect(next.time.currentStreak, 2);
    expect(next.time.lastActiveDay, '2026-10-27');
  });

  test('no toca la tienda', () {
    final next = calculator.applyMatch(PlayerStats.empty, match());

    expect(next.shop.toMap(), PlayerStats.empty.shop.toMap());
  });
}
