import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/widgets/board_view.dart';
import '../services/game_engine/test_board.dart';

void main() {
  final board = buildTestBoard();

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

  testWidgets('dibuja un tablero de más de 42 casillas sin romperse', (
    tester,
  ) async {
    final big = BoardLayout([
      for (var id = 0; id < 60; id++)
        BoardTile(
          id: id,
          type: id == 0 ? TileType.start : TileType.positive,
          next: [(id + 1) % 60],
        ),
    ]);
    const state = GameState(
      players: {
        'a': PlayerState(id: 'a', username: 'Ana', position: 55),
        // Partida guardada con otro tablero: la ficha no se dibuja.
        'b': PlayerState(id: 'b', username: 'Beto', position: 99),
      },
      turnOrder: ['a', 'b'],
      totalRounds: 5,
      diamondTileId: 50,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardView(board: big, state: state),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.diamond), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNWidgets(58));
  });
}
