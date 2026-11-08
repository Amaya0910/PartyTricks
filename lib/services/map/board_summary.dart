import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Qué tan grande es un tablero, para mostrarlo al elegir mapa.
enum BoardSize {
  small('Pequeño'),
  medium('Mediano'),
  large('Grande'),
  huge('Enorme');

  const BoardSize(this.label);

  final String label;

  /// Hasta 60 casillas es pequeño, hasta 100 mediano, hasta 130 grande y de
  /// ahí en adelante enorme. El primer mapa (42) es pequeño.
  static BoardSize of(int tiles) => switch (tiles) {
    <= 60 => small,
    <= 100 => medium,
    <= 130 => large,
    _ => huge,
  };
}

/// Lo que se cuenta de un tablero. Sale del tablero mismo, así que nunca
/// queda desactualizado.
class BoardSummary {
  const BoardSummary({
    required this.tiles,
    required this.forks,
    required this.shops,
  });

  factory BoardSummary.of(BoardLayout board) => BoardSummary(
    tiles: board.tiles.length,
    forks: board.tiles.where((tile) => tile.isFork).length,
    shops: board.tiles.where((tile) => tile.type == TileType.shop).length,
  );

  final int tiles;
  final int forks;
  final int shops;

  BoardSize get size => BoardSize.of(tiles);
}
