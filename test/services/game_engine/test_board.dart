import 'package:party_tricks/services/game_engine/board_layout.dart';

/// El tablero de antes (42 casillas, 3 bifurcaciones), solo para las pruebas
/// del motor. Así cambiar el mapa del juego no rompe estas pruebas.
BoardLayout buildTestBoard() {
  const lastMainTile = 29;
  const forks = {5: 30, 15: 34, 24: 38};
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