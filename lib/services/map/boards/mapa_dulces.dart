import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Tablero de Mundo Dulce: 60 casillas en forma de "ojo".
///
/// La Plaza de Caramelo (0–4) sale a la bifurcación 4, que abre el lóbulo
/// norte (5–26, con el Túnel de Galleta 11 → 49…53 → 20) y el lóbulo sur
/// (32–48, con la Cascada de Malvavisco 37 → 54…59 → 45). Los dos vuelven
/// a la 27 y la Avenida de Gomitas (27–31) cierra la vuelta en la salida.
///
/// Vueltas: norte 32 pasos, norte por el túnel 29, sur 27 y sur por la
/// cascada 26. El diseño completo está en el documento de producción de
/// Mundo Dulce y en `docs/decisiones.md` (D-32).
BoardLayout buildCandyBoard() {
  const lastMainTile = 31;
  // Casilla de la bifurcación -> primera casilla del camino alterno.
  const forks = {4: 32, 11: 49, 37: 54};
  // Última casilla del camino alterno -> casilla donde vuelve.
  const rejoins = {48: 27, 53: 20, 59: 45};
  const shops = {3, 16, 41};
  const specials = {9, 21, 29, 35, 46, 51, 56};
  const negatives = {6, 13, 18, 23, 26, 30, 33, 36, 39, 43, 47, 49, 52, 58};

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
    for (var id = 0; id <= 59; id++)
      BoardTile(id: id, type: typeFor(id), next: nextFor(id)),
  ]);
}
