import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/award_stats.dart';
import 'package:party_tricks/models/stats/board_stats.dart';
import 'package:party_tricks/models/stats/match_stats.dart';
import 'package:party_tricks/models/stats/minigame_stats.dart';
import 'package:party_tricks/models/stats/shop_stats.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/models/stats/time_stats.dart';

void main() {
  const stats = PlayerStats(
    matches: MatchStats(
      won: 5,
      lost: 5,
      ties: 1,
      firstPlaces: 5,
      totalDiamonds: 25,
      totalCoins: 200,
      longestMatchSeconds: 900,
    ),
    awards: AwardStats(minigames: 2, richest: 1),
    minigames: MinigameStats(
      won: 30,
      lost: 20,
      byType: {'carrera': MinigameTypeStats(played: 3, won: 2, bestScore: 9)},
    ),
    board: BoardStats(diceRolled: 4, diceTotal: 14, laps: 2),
    shop: ShopStats(
      chestsOpened: {'basic': 2, 'party': 1},
      diamondsSpent: 200,
      coinPrizes: 1,
      coinsFromChests: 100,
    ),
    social: SocialStats(
      messagesSent: 7,
      playedWith: {'u2': PartnerStats(username: 'Beto', matches: 3)},
    ),
    time: TimeStats(secondsInApp: 600, currentStreak: 2, lastActiveDay: 'x'),
  );

  test('toMap y fromMap son inversos', () {
    final copy = PlayerStats.fromMap(stats.toMap());

    expect(copy.toMap(), stats.toMap());
  });

  test('fromMap usa valores vacíos si faltan grupos o campos', () {
    final copy = PlayerStats.fromMap({
      'matches': {'won': 2.0},
    });

    expect(copy.matches.won, 2);
    expect(copy.matches.lost, 0);
    expect(copy.toMap()['shop'], PlayerStats.empty.toMap()['shop']);
    expect(copy.time.lastActiveDay, isNull);
  });

  group('partidas', () {
    test('porcentaje y promedio de diamantes', () {
      expect(stats.matches.played, 10);
      expect(stats.matches.winRate, 50);
      expect(stats.matches.averageDiamonds, 2.5);
    });

    test('sin partidas, porcentaje y promedio son 0', () {
      const empty = MatchStats();
      expect(empty.winRate, 0);
      expect(empty.averageDiamonds, 0);
    });

    test('el porcentaje se redondea', () {
      expect(const MatchStats(won: 1, lost: 2).winRate, 33);
    });
  });

  group('minijuegos por tipo', () {
    const minigames = MinigameStats(
      byType: {
        'carrera': MinigameTypeStats(played: 4, won: 1),
        'memoria': MinigameTypeStats(played: 2, won: 2),
        'saltos': MinigameTypeStats(played: 4, won: 0),
      },
    );

    test('el favorito es el más jugado; en un empate, por orden', () {
      expect(minigames.favoriteType, 'carrera');
    });

    test('el más ganado y los tipos jugados', () {
      expect(minigames.mostWonType, 'memoria');
      expect(minigames.typesPlayed, 3);
    });

    test('sin minijuegos no hay favorito', () {
      expect(const MinigameStats().favoriteType, isNull);
      expect(const MinigameStats().mostWonType, isNull);
    });
  });

  test('promedio del dado', () {
    expect(stats.board.averageRoll, 3.5);
    expect(const BoardStats().averageRoll, 0);
  });

  test('cofres por tipo y total', () {
    expect(stats.shop.opened(ChestType.basic), 2);
    expect(stats.shop.opened(ChestType.diamond), 0);
    expect(stats.shop.totalChests, 3);
  });

  test('compañero más frecuente', () {
    const social = SocialStats(
      playedWith: {
        'u1': PartnerStats(username: 'Ana', matches: 2),
        'u2': PartnerStats(username: 'Beto', matches: 5),
      },
    );

    expect(social.favoritePartner?.username, 'Beto');
    expect(const SocialStats().favoritePartner, isNull);
  });

  test('las monedas ganadas suman partidas y cofres', () {
    expect(stats.totalCoinsEarned, 300);
  });

  test('premios finales y su total', () {
    expect(stats.awards.total, 3);
    final sum = stats.awards.plus(const AwardStats(worstLuck: 1));
    expect(sum.worstLuck, 1);
    expect(sum.total, 4);
  });
}
