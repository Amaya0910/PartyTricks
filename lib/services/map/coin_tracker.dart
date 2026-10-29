/// Monedas de las casillas positivas que ya recogiste.
///
/// Es solo visual y vive en tu celular: cada jugador ve sus propias monedas.
/// Al pasar por una casilla con moneda se recoge y vuelve a aparecer al
/// empezar la siguiente ronda.
class CoinTracker {
  CoinTracker(Iterable<int> coinTiles) : _coinTiles = coinTiles.toSet();

  final Set<int> _coinTiles;
  final Set<int> _taken = {};
  int? _round;

  /// Casillas que tienen moneda.
  Iterable<int> get tiles => _coinTiles;

  /// Si la moneda de [tile] se ve ahora.
  bool isVisible(int tile) =>
      _coinTiles.contains(tile) && !_taken.contains(tile);

  /// Recoge la moneda de [tile]. Devuelve true si había una para recoger.
  bool collect(int tile) => _coinTiles.contains(tile) && _taken.add(tile);

  /// Avisa la ronda actual; si cambió, las monedas vuelven a aparecer.
  void onRound(int round) {
    if (_round != null && round != _round) _taken.clear();
    _round = round;
  }
}
