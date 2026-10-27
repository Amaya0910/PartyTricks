import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';

void main() {
  final board = buildDefaultBoard();

  test('tiene 42 casillas, 3 bifurcaciones y 2 tiendas', () {
    expect(board.tiles.length, 42);
    expect(board.tiles.where((t) => t.isFork).length, 3);
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

  test('al pasar la última casilla vuelve a la salida', () {
    expect(board.path(28, 3, (_) => 0), [29, 0, 1]);
  });

  test('en una bifurcación se puede tomar cualquier camino', () {
    expect(board.path(4, 3, (_) => 0), [5, 6, 7]);
    expect(board.path(4, 3, (_) => 1), [5, 30, 31]);
    expect(board.path(24, 2, (_) => 1), [38, 39]);
  });

  test('el camino alterno vuelve al principal', () {
    expect(board.path(32, 2, (_) => 0), [33, 10]);
    expect(board.path(40, 2, (_) => 0), [41, 29]);
  });
}
