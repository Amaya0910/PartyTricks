import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Datos de ejemplo para la galería del panel de administración. Sirven
/// para ver las pantallas sin jugar una partida; nada de esto se guarda.
abstract final class AdminSamples {
  /// Tu id en los ejemplos.
  static const me = 'yo';

  /// Los rivales de mentira que juegan contigo en la práctica.
  static const bots = ['beto', 'caro'];

  static const players = [me, ...bots];

  static final minigamePlayers = MinigamePlayers(
    names: const {me: 'Tú', 'beto': 'Beto', 'caro': 'Caro'},
    colors: {
      for (final (index, id) in players.indexed)
        id: AppColors.players[index % AppColors.players.length],
    },
  );

  /// Un resultado de ejemplo de cada minijuego.
  static const results = [
    MinigameResult(
      type: MinigameType.stopwatch,
      round: 1,
      winnerIds: ['beto'],
      targetMs: 7000,
      scores: {me: 7300, 'beto': 6900, 'caro': MinigameRules.noScore},
    ),
    MinigameResult(
      type: MinigameType.reaction,
      round: 2,
      winnerIds: [me],
      scores: {me: 241, 'beto': 260, 'caro': 260},
      tiebreak: {
        'beto': [3],
        'caro': [5],
      },
    ),
    MinigameResult(
      type: MinigameType.balloon,
      round: 3,
      winnerIds: ['caro'],
      out: ['beto', me],
    ),
    MinigameResult(
      type: MinigameType.reaction,
      round: 4,
      winnerIds: [],
      scores: {
        me: MinigameRules.noScore,
        'beto': MinigameRules.noScore,
        'caro': MinigameRules.noScore,
      },
    ),
  ];

  /// Una partida terminada, para la pantalla final.
  static const finishedGame = GameState(
    players: {
      me: PlayerState(
        id: me,
        username: 'Tú',
        diamonds: 3,
        coins: 25,
        diceRolled: 9,
        diceTotal: 31,
        purchases: 2,
        itemsUsed: 1,
        minigamesWon: 2,
        positiveTiles: 4,
      ),
      'beto': PlayerState(
        id: 'beto',
        username: 'Beto',
        diamonds: 2,
        coins: 40,
        negativeTiles: 6,
        diceRolled: 9,
        diceTotal: 28,
      ),
      'caro': PlayerState(
        id: 'caro',
        username: 'Caro',
        diamonds: 1,
        coins: 12,
        minigamesWon: 1,
        shortcutsTaken: 2,
      ),
    },
    turnOrder: players,
    totalRounds: 10,
    round: 10,
    diamondTileId: 1,
    phase: GamePhase.finished,
  );
}
