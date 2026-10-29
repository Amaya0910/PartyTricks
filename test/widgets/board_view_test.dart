import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/widgets/board_view.dart';
import '../services/game_engine/test_board.dart';

void main() {
  final board = buildTestBoard();
  final cells = defaultBoardCells();

  test('cada casilla tiene su propia celda dentro de la cuadrícula', () {
    expect(cells.length, board.tiles.length);
    expect(cells.values.toSet().length, board.tiles.length);
    for (final (x, y) in cells.values) {
      expect(x, inInclusiveRange(0, boardColumns - 1));
      expect(y, inInclusiveRange(0, boardRows - 1));
    }
  });

  test('cada casilla queda pegada a la siguiente', () {
    for (final tile in board.tiles) {
      final (x, y) = cells[tile.id]!;
      for (final next in tile.next) {
        final (nx, ny) = cells[next]!;
        expect(
          (x - nx).abs() <= 1 && (y - ny).abs() <= 1,
          isTrue,
          reason: 'La ${tile.id} no está pegada a la $next',
        );
      }
    }
  });

  testWidgets('dibuja las 42 casillas, el diamante y las fichas', (
    tester,
  ) async {
    const state = GameState(
      players: {
        'a': PlayerState(id: 'a', username: 'Ana', position: 3),
        'b': PlayerState(id: 'b', username: 'Beto', position: 3),
      },
      turnOrder: ['a', 'b'],
      totalRounds: 5,
      diamondTileId: 17,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardView(board: board, state: state),
        ),
      ),
    );

    expect(find.byIcon(Icons.diamond), findsOneWidget);
    expect(find.byIcon(Icons.storefront), findsNWidgets(2));
    expect(find.byIcon(Icons.flag), findsOneWidget);
  });

  testWidgets('dibuja las trampas puestas', (tester) async {
    const state = GameState(
      players: {'a': PlayerState(id: 'a', username: 'Ana')},
      turnOrder: ['a'],
      totalRounds: 5,
      diamondTileId: 17,
      traps: {4: 'a', 9: 'a'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardView(board: board, state: state),
        ),
      ),
    );

    expect(find.byIcon(Icons.dangerous), findsNWidgets(2));
  });
}
