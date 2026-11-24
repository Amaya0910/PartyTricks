import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/board_grid.dart';

import '../game_engine/test_board.dart';

/// Un camino de [length] casillas que vuelve a la salida.
BoardLayout _loop(int length) => BoardLayout([
  for (var id = 0; id < length; id++)
    BoardTile(
      id: id,
      type: id == 0 ? TileType.start : TileType.positive,
      next: [(id + 1) % length],
    ),
]);

bool _touching((int, int) a, (int, int) b) =>
    (a.$1 - b.$1).abs() <= 1 && (a.$2 - b.$2).abs() <= 1;

void main() {
  void expectFits(BoardLayout board) {
    final grid = BoardGrid.of(board);
    expect(grid.cells.keys.toSet(), {for (final t in board.tiles) t.id});
    expect(
      grid.cells.values.toSet().length,
      board.tiles.length,
      reason: 'Dos casillas en la misma celda',
    );
    for (final (x, y) in grid.cells.values) {
      expect(x, inInclusiveRange(0, grid.columns - 1));
      expect(y, inInclusiveRange(0, grid.rows - 1));
    }
  }

  test('cada casilla tiene su propia celda en tableros de varios tamaños', () {
    expectFits(buildDefaultBoard());
    expectFits(buildTestBoard());
    for (final length in [1, 2, 3, 7, 42, 60, 101]) {
      expectFits(_loop(length));
    }
  });

  test('el primer mapa queda en 9 × 9 y el de pruebas en 9 × 8', () {
    final first = BoardGrid.of(buildDefaultBoard());
    expect((first.columns, first.rows), (9, 9));
    final test = BoardGrid.of(buildTestBoard());
    expect((test.columns, test.rows), (9, 8));
  });

  test('el camino principal da la vuelta por el borde, pegado', () {
    final board = buildDefaultBoard();
    final grid = BoardGrid.of(board);
    for (var id = 0; id < 31; id++) {
      expect(
        _touching(grid.cells[id]!, grid.cells[id + 1]!),
        isTrue,
        reason: 'La $id no está pegada a la ${id + 1}',
      );
    }
    expect(_touching(grid.cells[31]!, grid.cells[0]!), isTrue);
    expect(grid.cells[0], (0, 0));
  });

  test('las casillas de cada atajo quedan pegadas entre sí', () {
    final grid = BoardGrid.of(buildDefaultBoard());
    for (final (from, to) in [(32, 36), (37, 41)]) {
      for (var id = from; id < to; id++) {
        expect(
          _touching(grid.cells[id]!, grid.cells[id + 1]!),
          isTrue,
          reason: 'La $id no está pegada a la ${id + 1}',
        );
      }
    }
  });

  test('si los atajos no caben adentro, agrega filas abajo', () {
    // Camino principal de 4 (2 × 2, sin espacio adentro) y un atajo de 5.
    final board = BoardLayout([
      const BoardTile(id: 0, type: TileType.start, next: [1, 4]),
      const BoardTile(id: 1, type: TileType.positive, next: [2]),
      const BoardTile(id: 2, type: TileType.positive, next: [3]),
      const BoardTile(id: 3, type: TileType.positive, next: [0]),
      for (var id = 4; id < 9; id++)
        BoardTile(
          id: id,
          type: TileType.negative,
          next: [id == 8 ? 2 : id + 1],
        ),
    ]);
    final grid = BoardGrid.of(board);

    expectFits(board);
    expect(grid.columns, 2);
    expect(grid.rows, 2 + 3);
  });

  test('tampoco se rompe con tableros mal armados', () {
    final broken = BoardLayout(const [
      BoardTile(id: 0, type: TileType.start, next: [7]),
      BoardTile(id: 1, type: TileType.positive, next: []),
      BoardTile(id: 2, type: TileType.positive, next: [2]),
    ]);

    expectFits(broken);
    expect(BoardGrid.of(const BoardLayout([])).cells, isEmpty);
  });
}
