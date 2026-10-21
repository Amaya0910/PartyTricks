import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Columnas y filas de la cuadrícula donde se dibuja el tablero.
const boardColumns = 9;
const boardRows = 8;

/// Celda (columna, fila) de cada casilla del tablero por defecto.
///
/// Provisional hasta tener el dibujo: el camino principal (0-29) da la vuelta
/// por el borde y los caminos alternos van por dentro.
Map<int, (int, int)> defaultBoardCells() {
  final cells = <int, (int, int)>{};
  var id = 0;
  for (var x = 0; x < boardColumns; x++) {
    cells[id++] = (x, 0); // 0-8: arriba
  }
  for (var y = 1; y < boardRows - 1; y++) {
    cells[id++] = (boardColumns - 1, y); // 9-14: derecha
  }
  for (var x = boardColumns - 1; x >= 0; x--) {
    cells[id++] = (x, boardRows - 1); // 15-23: abajo
  }
  for (var y = boardRows - 2; y >= 1; y--) {
    cells[id++] = (0, y); // 24-29: izquierda
  }
  // Caminos alternos: 30-33 (de la 5 a la 10), 34-37 (de la 15 a la 20) y
  // 38-41 (de la 24 a la 29).
  const inner = [
    (5, 1), (6, 1), (7, 1), (7, 2), //
    (7, 6), (6, 6), (5, 6), (4, 6), //
    (1, 5), (1, 4), (1, 3), (1, 2), //
  ];
  for (final cell in inner) {
    cells[id++] = cell;
  }
  return cells;
}

/// Dibuja el tablero con las fichas de los jugadores y el diamante.
class BoardView extends StatelessWidget {
  const BoardView({super.key, required this.board, required this.state});

  final BoardLayout board;
  final GameState state;

  static final _cells = defaultBoardCells();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: boardColumns / boardRows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth / boardColumns;
          return Stack(
            children: [
              for (final tile in board.tiles)
                _positioned(tile.id, size, _Tile(tile: tile, state: state)),
              for (final (index, id) in state.turnOrder.indexed)
                _positioned(
                  state.players[id]!.position,
                  size,
                  _Token(index: index, size: size),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _positioned(int tileId, double size, Widget child) {
    final (x, y) = _cells[tileId]!;
    return Positioned(
      left: x * size,
      top: y * size,
      width: size,
      height: size,
      child: child,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile, required this.state});

  final BoardTile tile;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (tile.type) {
      TileType.start => AppColors.tileStart,
      TileType.positive => AppColors.tilePositive,
      TileType.negative => AppColors.tileNegative,
      TileType.special => AppColors.tileSpecial,
      TileType.shop => AppColors.tileShop,
    };
    final icon = switch (tile.type) {
      TileType.start => Icons.flag,
      TileType.shop => Icons.storefront,
      TileType.special => Icons.question_mark,
      TileType.positive => Icons.add,
      TileType.negative => Icons.remove,
    };
    return Padding(
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white, width: 2),
        ),
        child: Center(
          child: tile.id == state.diamondTileId
              ? const Icon(Icons.diamond, color: AppColors.diamond)
              : Icon(icon, color: AppColors.white, size: 16),
        ),
      ),
    );
  }
}

/// Ficha de un jugador. Cada uno va en una esquina distinta de la casilla
/// para que no se tapen cuando caen en la misma.
class _Token extends StatelessWidget {
  const _Token({required this.index, required this.size});

  /// Posición del jugador en el orden de turnos.
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokenSize = size * 0.38;
    return Align(
      alignment: Alignment(
        index.isEven ? -0.7 : 0.7,
        -0.7 + (index ~/ 2) * 0.7,
      ),
      child: Container(
        width: tokenSize,
        height: tokenSize,
        decoration: BoxDecoration(
          color: AppColors.players[index % AppColors.players.length],
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2),
        ),
      ),
    );
  }
}
