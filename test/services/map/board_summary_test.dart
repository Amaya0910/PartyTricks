import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/board_summary.dart';

void main() {
  test('el tamaño sale de la cantidad de casillas', () {
    expect(BoardSize.of(42), BoardSize.small);
    expect(BoardSize.of(60), BoardSize.small);
    expect(BoardSize.of(70), BoardSize.medium);
    expect(BoardSize.of(100), BoardSize.medium);
    expect(BoardSize.of(120), BoardSize.large);
    expect(BoardSize.of(130), BoardSize.large);
    expect(BoardSize.of(150), BoardSize.huge);
  });

  test('cuenta casillas, atajos y tiendas del tablero', () {
    final summary = BoardSummary.of(buildDefaultBoard());

    expect(summary.tiles, 42);
    expect(summary.forks, 2);
    expect(summary.shops, 2);
    expect(summary.size, BoardSize.small);
  });
}
