import 'dart:collection';

import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Casillas por las que pasa el personaje para ir de una a otra, siguiendo
/// el camino del tablero. Sirve para animar la caminata.
class BoardWalk {
  const BoardWalk(this.board);

  final BoardLayout board;

  /// Las casillas desde [from] (sin incluirla) hasta [to] (incluida), por el
  /// camino más corto. Si [to] no se puede alcanzar, salta directo a ella.
  List<int> between(int from, int to) {
    if (from == to) return const [];
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
    return [to];
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
