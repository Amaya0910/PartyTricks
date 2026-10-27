/// Tipos de casilla del mapa (diseno_juego.md, sección 6).
enum TileType { start, positive, negative, special, shop }

/// Una casilla del mapa. Si [next] tiene más de una, es una bifurcación.
class BoardTile {
  const BoardTile({required this.id, required this.type, required this.next});

  final int id;
  final TileType type;
  final List<int> next;

  bool get isFork => next.length > 1;
}

/// Mapa cíclico con varios caminos. El id de cada casilla es su posición.
class BoardLayout {
  const BoardLayout(this.tiles);

  final List<BoardTile> tiles;

  static const startId = 0;

  BoardTile tile(int id) => tiles[id];

  /// Casillas por las que pasa un jugador al avanzar [steps] desde [from].
  ///
  /// La última es donde cae. En cada bifurcación se llama a [chooseBranch]
  /// para saber qué camino toma (0 = seguir el principal, 1 = el alterno).
  List<int> path(
    int from,
    int steps,
    int Function(BoardTile fork) chooseBranch,
  ) {
    final visited = <int>[];
    var current = from;
    for (var i = 0; i < steps; i++) {
      final tile = tiles[current];
      final branch = tile.isFork ? chooseBranch(tile) : 0;
      current = tile.next[branch];
      visited.add(current);
    }
    return visited;
  }
}

/// Tablero de 42 casillas y 3 bifurcaciones.
///
/// Las posiciones y los tipos son provisionales hasta tener el dibujo final.
BoardLayout buildDefaultBoard() {
  const lastMainTile = 29;
  // Casilla de la bifurcación -> primera casilla del camino alterno.
  const forks = {5: 30, 15: 34, 24: 38};
  // Última casilla del camino alterno -> casilla donde vuelve al principal.
  const rejoins = {33: 10, 37: 20, 41: 29};
  const shops = {12, 22};
  const specials = {3, 8, 14, 18, 26, 32, 36, 40};
  const negatives = {7, 11, 17, 21, 27, 31, 35, 39};

  TileType typeFor(int id) {
    if (id == BoardLayout.startId) return TileType.start;
    if (shops.contains(id)) return TileType.shop;
    if (specials.contains(id)) return TileType.special;
    if (negatives.contains(id)) return TileType.negative;
    return TileType.positive;
  }

  List<int> nextFor(int id) {
    if (forks.containsKey(id)) return [id + 1, forks[id]!];
    if (rejoins.containsKey(id)) return [rejoins[id]!];
    if (id == lastMainTile) return [BoardLayout.startId];
    return [id + 1];
  }

  return BoardLayout([
    for (var id = 0; id <= 41; id++)
      BoardTile(id: id, type: typeFor(id), next: nextFor(id)),
  ]);
}
