import 'dart:math';

import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Celdas de la cuadrícula del tablero de respaldo (el de cuadritos que se
/// usa si el mapa dibujado no carga). Se arman a partir del tablero, así que
/// sirven para cualquier mapa:
///
/// - El camino principal (siguiendo siempre el primer `next` desde la
///   salida) da la vuelta por el borde, empezando arriba a la izquierda.
/// - Los atajos van por dentro, en zigzag, una casilla pegada a la otra.
/// - Si no caben adentro, se agregan filas abajo.
class BoardGrid {
  const BoardGrid({
    required this.columns,
    required this.rows,
    required this.cells,
  });

  factory BoardGrid.of(BoardLayout board) {
    final tiles = board.tiles;
    if (tiles.isEmpty) return const BoardGrid(columns: 1, rows: 1, cells: {});
    bool exists(int id) => id >= 0 && id < tiles.length;

    final loop = <int>[];
    final placed = <int>{};
    for (
      var id = BoardLayout.startId;
      exists(id) && placed.add(id);
      id = tiles[id].next.isEmpty ? -1 : tiles[id].next.first
    ) {
      loop.add(id);
    }

    // Los atajos en el orden en que salen del camino; luego, lo que haya
    // quedado suelto.
    final order = [...loop];
    for (var i = 0; i < order.length; i++) {
      for (final branch in tiles[order[i]].next.skip(1)) {
        for (
          var id = branch;
          exists(id) && placed.add(id);
          id = tiles[id].next.isEmpty ? -1 : tiles[id].next.first
        ) {
          order.add(id);
        }
      }
    }
    for (var id = 0; id < tiles.length; id++) {
      if (placed.add(id)) order.add(id);
    }

    // Un borde par con lugar para todo el camino principal, lo más cuadrado
    // posible. Por ejemplo, 32 casillas → 9 × 9.
    final perimeter = max(4, loop.length + loop.length % 2);
    final sides = (perimeter + 4) ~/ 2;
    final columns = (sides + 1) ~/ 2;
    final ring = _ring(columns, sides - columns);

    final inner = [
      for (var y = 1; y < sides - columns - 1; y++)
        for (var i = 0; i < columns - 2; i++)
          ((y - 1).isEven ? 1 + i : columns - 2 - i, y),
    ];
    final rest = order.length - loop.length;
    final extraRows = rest > inner.length
        ? (rest - inner.length + columns - 1) ~/ columns
        : 0;
    final rows = sides - columns + extraRows;
    final below = [
      for (var y = rows - extraRows; y < rows; y++)
        for (var i = 0; i < columns; i++)
          ((y - rows + extraRows).isEven ? i : columns - 1 - i, y),
    ];

    final free = [...ring.take(loop.length), ...inner, ...below];
    return BoardGrid(
      columns: columns,
      rows: rows,
      cells: {for (final (i, id) in order.indexed) id: free[i]},
    );
  }

  final int columns;
  final int rows;

  /// Celda (columna, fila) de cada casilla.
  final Map<int, (int, int)> cells;

  /// El borde de la cuadrícula en el sentido de las agujas del reloj.
  static List<(int, int)> _ring(int columns, int rows) => [
    for (var x = 0; x < columns; x++) (x, 0),
    for (var y = 1; y < rows - 1; y++) (columns - 1, y),
    for (var x = columns - 1; x >= 0; x--) (x, rows - 1),
    for (var y = rows - 2; y >= 1; y--) (0, y),
  ];
}
