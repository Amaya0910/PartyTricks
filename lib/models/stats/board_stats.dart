import 'package:party_tricks/models/stats/stats_map.dart';

/// Lo que pasó en el tablero: dados, casillas, caminos y vueltas. Sirve para
/// el total del jugador y para una sola partida.
class BoardStats {
  const BoardStats({
    this.diceRolled = 0,
    this.diceTotal = 0,
    this.maxRolls = 0,
    this.positiveTiles = 0,
    this.negativeTiles = 0,
    this.specialTiles = 0,
    this.mainPathsTaken = 0,
    this.shortcutsTaken = 0,
    this.laps = 0,
    this.mapDiamonds = 0,
    this.shopPurchases = 0,
  });

  final int diceRolled;

  /// Suma de todo lo que sacó en el dado.
  final int diceTotal;

  /// Veces que sacó el número más alto del dado.
  final int maxRolls;

  final int positiveTiles;
  final int negativeTiles;
  final int specialTiles;
  final int mainPathsTaken;
  final int shortcutsTaken;

  /// Vueltas completas al mapa.
  final int laps;

  /// Diamantes recogidos en el mapa.
  final int mapDiamonds;

  /// Compras en las tiendas del mapa.
  final int shopPurchases;

  /// Promedio del dado (0 si no ha lanzado).
  double get averageRoll => diceRolled == 0 ? 0 : diceTotal / diceRolled;

  BoardStats plus(BoardStats other) {
    return BoardStats(
      diceRolled: diceRolled + other.diceRolled,
      diceTotal: diceTotal + other.diceTotal,
      maxRolls: maxRolls + other.maxRolls,
      positiveTiles: positiveTiles + other.positiveTiles,
      negativeTiles: negativeTiles + other.negativeTiles,
      specialTiles: specialTiles + other.specialTiles,
      mainPathsTaken: mainPathsTaken + other.mainPathsTaken,
      shortcutsTaken: shortcutsTaken + other.shortcutsTaken,
      laps: laps + other.laps,
      mapDiamonds: mapDiamonds + other.mapDiamonds,
      shopPurchases: shopPurchases + other.shopPurchases,
    );
  }

  factory BoardStats.fromMap(Map<String, dynamic> map) {
    int read(String key) => StatsMap.readInt(map, key);
    return BoardStats(
      diceRolled: read('diceRolled'),
      diceTotal: read('diceTotal'),
      maxRolls: read('maxRolls'),
      positiveTiles: read('positiveTiles'),
      negativeTiles: read('negativeTiles'),
      specialTiles: read('specialTiles'),
      mainPathsTaken: read('mainPathsTaken'),
      shortcutsTaken: read('shortcutsTaken'),
      laps: read('laps'),
      mapDiamonds: read('mapDiamonds'),
      shopPurchases: read('shopPurchases'),
    );
  }

  Map<String, dynamic> toMap() => {
    'diceRolled': diceRolled,
    'diceTotal': diceTotal,
    'maxRolls': maxRolls,
    'positiveTiles': positiveTiles,
    'negativeTiles': negativeTiles,
    'specialTiles': specialTiles,
    'mainPathsTaken': mainPathsTaken,
    'shortcutsTaken': shortcutsTaken,
    'laps': laps,
    'mapDiamonds': mapDiamonds,
    'shopPurchases': shopPurchases,
  };
}
