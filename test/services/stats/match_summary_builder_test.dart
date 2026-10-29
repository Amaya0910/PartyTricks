import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/stats/match_summary_builder.dart';

GameState game({
  GamePhase phase = GamePhase.finished,
  List<PlayerState> players = const [
    PlayerState(
      id: 'a',
      username: 'Ana',
      diamonds: 2,
      coins: 30,
      minigamesWon: 3,
      diceRolled: 5,
      diceTotal: 18,
      maxRolls: 1,
      laps: 1,
      shortcutsTaken: 2,
      mapDiamonds: 2,
      purchases: 1,
    ),
    PlayerState(
      id: 'b',
      username: 'Beto',
      diamonds: 1,
      coins: 5,
      negativeTiles: 3,
    ),
    PlayerState(id: 'c', username: 'Caro'),
  ],
}) {
  return GameState(
    players: {for (final p in players) p.id: p},
    turnOrder: [for (final p in players) p.id],
    totalRounds: 5,
    round: 5,
    diamondTileId: 1,
    phase: phase,
  );
}

void main() {
  const builder = MatchSummaryBuilder();

  test('el ganador: puesto, diamantes finales, premios y tablero', () {
    final summary = builder.build(
      matchId: 'sala-1',
      game: game(),
      playerId: 'a',
      isHost: true,
      isPublic: true,
      playingTime: const Duration(minutes: 10),
      minigameTime: const Duration(minutes: 3),
    )!;

    expect(summary.matchId, 'sala-1');
    expect(summary.won, isTrue);
    expect(summary.tied, isFalse);
    expect(summary.place, 1);
    // 2 del tablero + minijuegos (3) + más monedas (30) + comprador = 5.
    expect(summary.diamonds, 5);
    expect(summary.coins, 30);
    expect(summary.rounds, 5);
    expect(summary.isHost, isTrue);
    expect(summary.isPublic, isTrue);
    expect(summary.awards.minigames, 1);
    expect(summary.awards.richest, 1);
    expect(summary.awards.topBuyer, 1);
    expect(summary.awards.worstLuck, 0);
    expect(summary.board.diceRolled, 5);
    expect(summary.board.diceTotal, 18);
    expect(summary.board.maxRolls, 1);
    expect(summary.board.laps, 1);
    expect(summary.board.shortcutsTaken, 2);
    expect(summary.board.mapDiamonds, 2);
    expect(summary.board.shopPurchases, 1);
    expect(summary.minigamesWon, 3);
    expect(summary.minigamesPlayed, 5);
    expect(summary.minigamesLost, 2);
    expect(summary.opponents, {'b': 'Beto', 'c': 'Caro'});
    expect(summary.playingTime, const Duration(minutes: 10));
    expect(summary.minigameTime, const Duration(minutes: 3));
  });

  test('el que no ganó: perdido, con su puesto y sus premios', () {
    final summary = builder.build(
      matchId: 'sala-1',
      game: game(),
      playerId: 'b',
    )!;

    expect(summary.won, isFalse);
    expect(summary.place, 2);
    expect(summary.awards.worstLuck, 1);
    expect(summary.board.negativeTiles, 3);
    expect(summary.minigamesLost, 5);
    expect(summary.isHost, isFalse);
  });

  test('en un empate, todos los empatados ganan y queda como empate', () {
    final summary = builder.build(
      matchId: 'sala-1',
      game: game(
        players: const [
          PlayerState(id: 'a', username: 'Ana', diamonds: 1),
          PlayerState(id: 'b', username: 'Beto', diamonds: 1),
        ],
      ),
      playerId: 'b',
    )!;

    expect(summary.won, isTrue);
    expect(summary.tied, isTrue);
    expect(summary.place, 1);
  });

  test('devuelve null si la partida no ha terminado', () {
    final summary = builder.build(
      matchId: 'sala-1',
      game: game(phase: GamePhase.rolling),
      playerId: 'a',
    );

    expect(summary, isNull);
  });

  test('devuelve null si el jugador no estaba en la partida', () {
    final summary = builder.build(
      matchId: 'sala-1',
      game: game(),
      playerId: 'zzz',
    );

    expect(summary, isNull);
  });

  test('guarda la XP de la partida según el puesto', () {
    // 3 jugadores y 5 rondas: 100 × 1,15 × 0,75 = 86 para el primero.
    final first = builder.build(matchId: 's', game: game(), playerId: 'a')!;
    final last = builder.build(matchId: 's', game: game(), playerId: 'c')!;

    expect(first.experience, 86);
    expect(last.experience, 26);
  });
}
