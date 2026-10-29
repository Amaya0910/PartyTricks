import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';

/// Lo que hace el anfitrión para que un minijuego no se quede esperando a
/// alguien que no juega (se fue, se le cerró la app o se distrajo).
///
/// Cuenta desde que ve cada paso del minijuego y, pasado el tiempo de
/// [MinigameRules.timeLimit], pide [MinigameTimeout]. Si cambia el
/// anfitrión, el nuevo empieza a contar desde que lo ve: a lo mucho se
/// espera un poco más, nunca se cierra antes de tiempo.
///
/// No depende de Firebase ni del reloj: recibe la hora, así se prueba solo.
class MinigameReferee {
  MinigameReferee({this.rules = const MinigameRules()});

  final MinigameRules rules;

  /// El paso que se está esperando ("ronda/paso") y desde cuándo.
  String? _waiting;
  DateTime? _since;

  /// La acción que hay que mandar ahora, o null si todavía no toca.
  MinigameTimeout? check(GameState game, DateTime now) {
    if (game.phase != GamePhase.minigame) {
      _waiting = null;
      return null;
    }
    final minigame = game.minigame;
    final waiting = '${game.round}/${minigame?.step ?? 'sin-minijuego'}';
    final since = _since;
    if (waiting != _waiting || since == null) {
      _waiting = waiting;
      _since = now;
      return null;
    }
    final limit = minigame == null
        ? Duration(milliseconds: rules.legacyWaitMs)
        : rules.timeLimit(minigame);
    if (now.difference(since) < limit) return null;
    // Si la acción se pierde, se vuelve a pedir después de otro plazo.
    _since = now;
    return MinigameTimeout(game.round, minigame?.step ?? 0);
  }
}
