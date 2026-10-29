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

/// Tablero del primer mapa dibujado: 42 casillas y 2 bifurcaciones.
///
/// El camino principal va de la 0 a la 31 y vuelve a la salida. Los dos
/// desvíos son atajos. Las posiciones están en `assets/maps/mapa_01/mapa.tmj`.
BoardLayout buildDefaultBoard() {
  const lastMainTile = 31;
  // Casilla de la bifurcación -> primera casilla del desvío.
  const forks = {1: 32, 13: 37};
  // Última casilla del desvío -> casilla donde vuelve al principal.
  const rejoins = {36: 8, 41: 23};
  const shops = {17, 36};
  const specials = {6, 22, 27, 39};
  const negatives = {5, 7, 9, 12, 14, 16, 18, 20, 26, 28, 31, 32, 35, 37};

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