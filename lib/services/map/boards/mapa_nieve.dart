import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Tablero de Reino Nevado: 42 casillas que suben la montaña en zigzag por
/// la izquierda y bajan por la derecha.
///
/// Dos atajos: el Puente de Hielo cruza el lago de arriba (14 → 36…39 →
/// 22, ahorra 3 pasos con dos negativas) y la Cueva de Hielo baja por el
/// borde derecho (28 → 40…41 → 32, ahorra 1). La 35 vuelve a la salida.
///
/// Vueltas: 36 pasos, 33 por el puente, 35 por la cueva y 32 por los dos.
/// Es la versión tráiler: casillas y atajos definitivos, arte provisional.
BoardLayout buildSnowBoard() {
  const lastMainTile = 35;
  // Casilla de la bifurcación -> primera casilla del camino alterno.
  const forks = {14: 36, 28: 40};
  // Última casilla del camino alterno -> casilla donde vuelve.
  const rejoins = {39: 22, 41: 32};
  const shops = {3, 18, 33};
  const specials = {9, 20, 26, 37, 40};
  const negatives = {6, 11, 16, 24, 30, 35, 36, 38};

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
