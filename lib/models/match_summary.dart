import 'package:party_tricks/models/stats/award_stats.dart';
import 'package:party_tricks/models/stats/board_stats.dart';
import 'package:party_tricks/models/stats/minigame_stats.dart';

/// Lo que un jugador se lleva de una partida terminada, para sus estadísticas.
class MatchSummary {
  const MatchSummary({
    required this.matchId,
    required this.won,
    required this.place,
    required this.diamonds,
    required this.coins,
    required this.minigamesWon,
    required this.minigamesPlayed,
    this.tied = false,
    this.experience = 0,
    this.disconnected = false,
    this.rounds = 0,
    this.isHost = false,
    this.isPublic = false,
    this.awards = const AwardStats(),
    this.board = const BoardStats(),
    this.minigamesByType = const {},
    this.opponents = const {},
    this.playedWithFriend = false,
    this.playingTime = Duration.zero,
    this.minigameTime = Duration.zero,
  });

  /// Id de la sala. Sirve para no contar dos veces la misma partida.
  final String matchId;

  /// Si quedó entre los ganadores (en un empate, todos ganan).
  final bool won;

  /// Si ganó compartiendo el primer lugar.
  final bool tied;

  /// Puesto final: 1, 2, 3... Los empatados comparten puesto.
  final int place;

  /// Diamantes al final, ya con los diamantes finales sumados.
  final int diamonds;

  /// Monedas al final de la partida.
  final int coins;

  /// XP que ganó en la partida (diseno_juego.md, sección 11.1).
  final int experience;

  /// Terminó desconectado: no se lleva XP, monedas ni diamantes a la cuenta.
  final bool disconnected;

  final int rounds;

  /// Si creó la sala (fue el anfitrión).
  final bool isHost;
  final bool isPublic;

  /// Diamantes finales que ganó en esta partida (0 o 1 cada uno).
  final AwardStats awards;

  /// Lo que hizo en el tablero en esta partida.
  final BoardStats board;

  final int minigamesWon;
  final int minigamesPlayed;

  /// Cómo le fue en cada minijuego de la partida, por id del minijuego.
  final Map<String, MinigameTypeStats> minigamesByType;

  /// Los demás jugadores de la partida: uid → nombre.
  final Map<String, String> opponents;

  /// Si jugó con al menos un amigo. Llega con `feature/friends-chat`.
  final bool playedWithFriend;

  /// Tiempo dentro de la partida (tablero y minijuegos).
  final Duration playingTime;

  /// Tiempo dentro de los minijuegos (incluido en [playingTime]).
  final Duration minigameTime;

  int get minigamesLost {
    final lost = minigamesPlayed - minigamesWon;
    return lost < 0 ? 0 : lost;
  }

  /// Mejor puntaje en un minijuego de esta partida (0 si no hay puntajes).
  int get bestMinigameScore {
    var best = 0;
    for (final minigame in minigamesByType.values) {
      if (minigame.bestScore > best) best = minigame.bestScore;
    }
    return best;
  }
}
