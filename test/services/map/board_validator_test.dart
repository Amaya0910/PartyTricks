import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/board_validator.dart';

import '../game_engine/test_board.dart';

/// Salida (0) → 1 → 2 → 3 → salida, con un atajo 1 → 4 → 3.
/// Una lista nueva cada vez, para poder cambiarla.
List<BoardTile> _tiles() => [
  const BoardTile(id: 0, type: TileType.start, next: [1]),
  const BoardTile(id: 1, type: TileType.positive, next: [2, 4]),
  const BoardTile(id: 2, type: TileType.shop, next: [3]),
  const BoardTile(id: 3, type: TileType.negative, next: [0]),
  const BoardTile(id: 4, type: TileType.special, next: [3]),
];

/// [tiles] con la casilla [id] cambiada.
BoardLayout _with(int id, {TileType? type, List<int>? next, int? newId}) {
  final tiles = _tiles();
  final old = tiles[id];
  tiles[id] = BoardTile(
    id: newId ?? old.id,
    type: type ?? old.type,
    next: next ?? old.next,
  );
  return BoardLayout(tiles);
}

BoardMap _drawn(Iterable<int> ids) => BoardMap(
  size: const Size(100, 100),
  tiles: {
    for (final id in ids)
      id: MapTile(
        id: id,
        sprite: MapSprite(asset: 'a.png', rect: Rect.fromLTWH(0, 0, 1, 1)),
      ),
  },
  objects: const [],
  background: 'fondo.png',
);

List<BoardProblemKind> _kinds(Iterable<BoardProblem> problems) => [
  for (final problem in problems) problem.kind,
];

void main() {
  test('un tablero bien armado no tiene problemas', () {
    expect(validateBoard(BoardLayout(_tiles())), isEmpty);
    expect(validateBoard(buildTestBoard()), isEmpty);
  });

  test('avisa si el tablero está vacío', () {
    expect(_kinds(validateBoard(const BoardLayout([]))), [
      BoardProblemKind.empty,
    ]);
  });

  test('detecta ids que no van seguidos desde 0', () {
    final problems = validateBoard(_with(2, newId: 7));

    expect(_kinds(problems), [BoardProblemKind.idOutOfOrder]);
    expect(problems.single.message, contains('posición 2'));
    expect(problems.single.message, contains('casilla 7'));
  });

  test('detecta un tablero al que le falta una casilla en medio', () {
    final tiles = _tiles()..removeAt(2);
    final problems = validateBoard(BoardLayout(tiles));

    expect(_kinds(problems), contains(BoardProblemKind.idOutOfOrder));
  });

  test('la casilla 0 tiene que ser la salida, y solo ella', () {
    expect(_kinds(validateBoard(_with(0, type: TileType.positive))), [
      BoardProblemKind.missingStart,
    ]);
    final extra = validateBoard(_with(2, type: TileType.start));
    expect(_kinds(extra), [BoardProblemKind.extraStart]);
    expect(extra.single.tileId, 2);
  });

  test('detecta next que apunta a una casilla que no existe', () {
    final problems = validateBoard(_with(2, next: [9]));

    expect(_kinds(problems), contains(BoardProblemKind.invalidNext));
    final invalid = problems.firstWhere(
      (p) => p.kind == BoardProblemKind.invalidNext,
    );
    expect(invalid.tileId, 2);
    expect(invalid.message, 'La casilla 2 lleva a la 9, que no existe.');
    // Y por eso la 2 queda sin forma de seguir hacia la salida.
    expect(_kinds(problems), contains(BoardProblemKind.noWayBack));
  });

  test('detecta next negativos, repetidos y a sí misma', () {
    expect(
      _kinds(validateBoard(_with(1, next: [2, -1]))),
      contains(BoardProblemKind.invalidNext),
    );
    expect(_kinds(validateBoard(_with(1, next: [2, 2]))), [
      BoardProblemKind.repeatedNext,
      BoardProblemKind.unreachable,
    ]);
    expect(_kinds(validateBoard(_with(2, next: [2, 3]))), [
      BoardProblemKind.selfLoop,
    ]);
  });

  test('detecta callejones sin salida', () {
    // Solo la 3 volvía a la salida: las demás quedan sin forma de volver.
    final problems = validateBoard(_with(3, next: []));

    expect(problems.first.kind, BoardProblemKind.deadEnd);
    expect(problems.first.tileId, 3);
    expect(_kinds(problems.skip(1)), everyElement(BoardProblemKind.noWayBack));
    expect({for (final p in problems.skip(1)) p.tileId}, {1, 2, 4});
  });

  test('no acepta más de dos caminos', () {
    expect(_kinds(validateBoard(_with(1, next: [2, 4, 3]))), [
      BoardProblemKind.tooManyBranches,
    ]);
  });

  test('detecta casillas a las que no se llega desde la salida', () {
    // Nadie lleva a la 4.
    final problems = validateBoard(_with(1, next: [2]));

    expect(_kinds(problems), [BoardProblemKind.unreachable]);
    expect(problems.single.tileId, 4);
  });

  test('detecta ciclos que no vuelven a la salida', () {
    // 3 ↔ 4: quien entra al atajo da vueltas para siempre.
    final tiles = _tiles();
    tiles[3] = const BoardTile(id: 3, type: TileType.negative, next: [4]);
    final problems = validateBoard(BoardLayout(tiles));

    expect(_kinds(problems), everyElement(BoardProblemKind.noWayBack));
    expect({for (final p in problems) p.tileId}, {1, 2, 3, 4});
  });

  group('con el mapa dibujado', () {
    final board = BoardLayout(_tiles());

    test('coincide si están dibujadas exactamente las mismas casillas', () {
      expect(validateBoard(board, map: _drawn([0, 1, 2, 3, 4])), isEmpty);
    });

    test('detecta casillas sin dibujar', () {
      final problems = validateBoard(board, map: _drawn([0, 1, 3]));

      expect(_kinds(problems), [
        BoardProblemKind.missingVisual,
        BoardProblemKind.missingVisual,
      ]);
      expect([for (final p in problems) p.tileId], [2, 4]);
    });

    test('detecta plataformas que el tablero no tiene', () {
      final problems = validateBoard(board, map: _drawn([0, 1, 2, 3, 4, 8, 5]));

      expect(_kinds(problems), [
        BoardProblemKind.orphanVisual,
        BoardProblemKind.orphanVisual,
      ]);
      expect([for (final p in problems) p.tileId], [5, 8]);
      expect(problems.first.message, contains('"casilla" = 5'));
    });
  });
}
