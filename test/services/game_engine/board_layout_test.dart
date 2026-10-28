import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';

void main() {
  final board = buildDefaultBoard();

   test('tiene 42 casillas, 2 bifurcaciones y 2 tiendas', () {
    expect(board.tiles.length, 42);
    expect(board.tiles.where((t) => t.isFork).length, 2);
    expect(board.tiles.where((t) => t.type == TileType.shop).length, 2);
    expect(board.tile(BoardLayout.startId).type, TileType.start);
  });

  test('cada casilla apunta a casillas que existen', () {
    for (final tile in board.tiles) {
      expect(tile.id, board.tiles.indexOf(tile));
      for (final next in tile.next) {
        expect(next, inInclusiveRange(0, board.tiles.length - 1));
      }
    }
  });

  test('se puede llegar a todas las casillas desde la salida', () {
    final reached = <int>{BoardLayout.startId};
    final pending = [BoardLayout.startId];
    while (pending.isNotEmpty) {
      for (final next in board.tile(pending.removeLast()).next) {
        if (reached.add(next)) pending.add(next);
      }
    }
    expect(reached.length, board.tiles.length);
  });

  test('tiene 42 casillas, 2 bifurcaciones y 2 tiendas', () {
    expect(board.tiles.length, 42);
    expect(board.tiles.where((t) => t.isFork).length, 2);
    expect(board.tiles.where((t) => t.type == TileType.shop).length, 2);
    expect(board.tile(BoardLayout.startId).type, TileType.start);
  });
}
