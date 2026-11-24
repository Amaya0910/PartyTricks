import 'dart:collection';

import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';

/// Cómo caminó un jugador desde una bifurcación donde estaba detenido: la
/// casilla de la bifurcación, cuántos pasos dio desde ahí y, si se sabe,
/// qué camino eligió (0 = principal, 1 = atajo).
typedef ForkWalk = ({int from, int steps, int? branch});

/// Casillas por las que pasa el personaje para ir de una a otra, siguiendo
/// el camino del tablero. Sirve para animar la caminata.
class BoardWalk {
  const BoardWalk(this.board);

  final BoardLayout board;

  /// Las casillas desde [from] (sin incluirla) hasta [to] (incluida).
  ///
  /// Si el jugador venía de una bifurcación ([fork], con `fork.from ==
  /// from`), sigue la ruta que eligió: la que empieza por ese camino y
  /// tiene exactamente esos pasos. Si no, o si ninguna ruta cumple, va por
  /// el camino más corto. Si [to] no se puede alcanzar, salta directo a
  /// ella.
  List<int> between(int from, int to, {ForkWalk? fork}) {
    if (from == to) return const [];
    if (fork != null && fork.from == from) {
      final route = _exact(from, to, fork.steps, fork.branch);
      if (route != null) return route;
    }
    return _shortest(from, to) ?? [to];
  }

  /// Una ruta de exactamente [steps] pasos de [from] a [to] cuyo primer paso
  /// es el camino [branch] (o cualquiera, si es null). Si hay varias, la que
  /// toma los caminos principales.
  List<int>? _exact(int from, int to, int steps, int? branch) {
    // Más pasos que esto es un dato raro: no vale la pena buscar.
    if (steps <= 0 || steps > board.tiles.length * 2) return null;
    final first = board.tile(from).next;
    if (branch != null && (branch < 0 || branch >= first.length)) return null;
    final route = <int>[];
    bool search(int tile, int left) {
      if (left == 0) return tile == to;
      final options = route.isEmpty && branch != null
          ? [first[branch]]
          : board.tile(tile).next;
      for (final next in options) {
        route.add(next);
        if (search(next, left - 1)) return true;
        route.removeLast();
      }
      return false;
    }

    return search(from, steps) ? route : null;
  }

  List<int>? _shortest(int from, int to) {
    final previous = <int, int>{};
    final queue = Queue<int>()..add(from);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final next in board.tile(current).next) {
        if (next == from || previous.containsKey(next)) continue;
        previous[next] = current;
        if (next == to) return _route(previous, from, to);
        queue.add(next);
      }
    }
    return null;
  }

  List<int> _route(Map<int, int> previous, int from, int to) {
    final route = <int>[to];
    var current = to;
    while (previous[current] != from) {
      current = previous[current]!;
      route.add(current);
    }
    return route.reversed.toList();
  }
}

/// Si [playerId] estaba detenido en una bifurcación en [before], cómo caminó
/// hasta [after]; null si no.
///
/// Sale de lo que ya trae la partida, sin campos nuevos:
/// - Los pasos: los que le quedaban al detenerse (`stepsLeft`), menos los
///   que le quedan si se volvió a detener en otra bifurcación.
/// - El camino: cuál de sus contadores de caminos subió en uno. Sirve para
///   desempatar si dos caminos llegan a la misma casilla con los mismos
///   pasos.
ForkWalk? forkWalkBetween(GameState before, GameState after, String playerId) {
  if (before.phase != GamePhase.choosingBranch ||
      before.currentPlayerId != playerId) {
    return null;
  }
  final was = before.players[playerId];
  final now = after.players[playerId];
  if (was == null || now == null) return null;
  // Se detiene otra vez en una bifurcación o en una tienda de paso: solo se
  // camina hasta ahí, y los pasos que quedan son del siguiente tramo.
  final stoppedAgain =
      (after.phase == GamePhase.choosingBranch ||
          after.phase == GamePhase.shopping) &&
      after.currentPlayerId == playerId;
  final main = now.mainPathsTaken - was.mainPathsTaken;
  final shortcuts = now.shortcutsTaken - was.shortcutsTaken;
  return (
    from: was.position,
    steps: before.stepsLeft - (stoppedAgain ? after.stepsLeft : 0),
    branch: switch ((main, shortcuts)) {
      (1, 0) => 0,
      (0, 1) => 1,
      _ => null,
    },
  );
}
