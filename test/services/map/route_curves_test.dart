import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/route_curves.dart';
import 'package:party_tricks/services/map/tiled_map_parser.dart';

BoardMap _mapOf(Map<int, Offset> anchors) => BoardMap(
  size: const Size(1000, 1000),
  tiles: {
    for (final e in anchors.entries)
      e.key: MapTile(
        id: e.key,
        sprite: MapSprite(
          asset: 'x.png',
          rect: Rect.fromCenter(center: e.value, width: 10, height: 10),
        ),
      ),
  },
  objects: const [],
  background: 'fondo.png',
);

BoardLayout _loop(int count) => BoardLayout([
  for (var i = 0; i < count; i++)
    BoardTile(
      id: i,
      type: i == 0 ? TileType.start : TileType.positive,
      next: [(i + 1) % count],
    ),
]);

void main() {
  group('los caminos suaves', () {
    test('si las casillas están en línea recta, el camino queda recto', () {
      final anchors = {for (var i = 0; i < 4; i++) i: Offset(100.0 * i, 0)};
      // Solo se usan los tramos 0→1, 1→2 y 2→3 (3→0 cierra el ciclo).
      final routes = RouteCurves.build(_mapOf(anchors), _loop(4));
      final curve = routes.curve(
        1,
        2,
        fallbackFrom: anchors[1]!,
        fallbackTo: anchors[2]!,
      );
      expect(RouteCurves.bulge(curve), lessThan(1));
    });

    test('en una esquina el camino se redondea y no tiene quiebre', () {
      // 0 → 1 → 2 con una esquina de 90 grados en la casilla 1.
      final anchors = {
        0: const Offset(0, 0),
        1: const Offset(300, 0),
        2: const Offset(300, 300),
      };
      final board = BoardLayout(const [
        BoardTile(id: 0, type: TileType.start, next: [1]),
        BoardTile(id: 1, type: TileType.positive, next: [2]),
        BoardTile(id: 2, type: TileType.positive, next: []),
      ]);
      final routes = RouteCurves.build(_mapOf(anchors), board);
      final a = routes.curve(
        0,
        1,
        fallbackFrom: anchors[0]!,
        fallbackTo: anchors[1]!,
      );
      final b = routes.curve(
        1,
        2,
        fallbackFrom: anchors[1]!,
        fallbackTo: anchors[2]!,
      );
      // Se curvan (ya no son rectas)...
      expect(RouteCurves.bulge(a), greaterThan(5));
      expect(RouteCurves.bulge(b), greaterThan(5));
      // ...y donde se unen van en la misma dirección.
      expect((a.endDirection - b.startDirection).distance, lessThan(1e-6));
    });

    test('empiezan y terminan justo en sus casillas', () {
      final anchors = {
        0: const Offset(50, 80),
        1: const Offset(400, 120),
        2: const Offset(420, 500),
      };
      final board = BoardLayout(const [
        BoardTile(id: 0, type: TileType.start, next: [1]),
        BoardTile(id: 1, type: TileType.positive, next: [2]),
        BoardTile(id: 2, type: TileType.positive, next: [0]),
      ]);
      final routes = RouteCurves.build(_mapOf(anchors), board);
      for (final entry in {(0, 1), (1, 2), (2, 0)}) {
        final c = routes.curve(
          entry.$1,
          entry.$2,
          fallbackFrom: anchors[entry.$1]!,
          fallbackTo: anchors[entry.$2]!,
        );
        expect((c.pointAt(0) - anchors[entry.$1]!).distance, lessThan(1e-6));
        expect((c.pointAt(1) - anchors[entry.$2]!).distance, lessThan(1e-6));
      }
    });

    test('el personaje avanza a paso parejo por la curva', () {
      final c = RouteCurve(
        const Offset(0, 0),
        const Offset(300, 0),
        const Offset(300, 300),
        const Offset(0, 300),
      );
      final steps = [
        for (var i = 0; i < 10; i++)
          (c.pointAt((i + 1) / 10) - c.pointAt(i / 10)).distance,
      ];
      final mean = steps.reduce((a, b) => a + b) / steps.length;
      for (final s in steps) {
        expect(s, closeTo(mean, mean * 0.12));
      }
    });

    test('entre casillas sin camino va en línea recta', () {
      final routes = RouteCurves.build(_mapOf({0: Offset.zero}), _loop(1));
      final c = routes.curve(
        3,
        9,
        fallbackFrom: const Offset(0, 0),
        fallbackTo: const Offset(100, 0),
      );
      expect(c.pointAt(0.5).dx, closeTo(50, 1));
      expect(c.pointAt(0.5).dy, closeTo(0, 1e-6));
    });
  });

  group('en el primer mapa', () {
    final json =
        jsonDecode(File('assets/maps/mapa_01/mapa.tmj').readAsStringSync())
            as Map<String, dynamic>;
    final map = TiledMapParser().parse(json, mapDir: 'assets/maps/mapa_01');
    final board = buildDefaultBoard();
    final routes = RouteCurves.build(map, board);

    test('cada tramo del tablero tiene su curva', () {
      var edges = 0;
      for (final tile in board.tiles) {
        edges += tile.next.length;
      }
      expect(routes.all.length, edges);
    });

    test('en las casillas sin bifurcación no hay quiebres', () {
      for (final tile in board.tiles) {
        if (tile.next.length != 1) continue;
        final next = board.tile(tile.next.single);
        if (next.next.length != 1) continue;
        final a = routes.curve(
          tile.id,
          next.id,
          fallbackFrom: map.tiles[tile.id]!.anchor,
          fallbackTo: map.tiles[next.id]!.anchor,
        );
        final b = routes.curve(
          next.id,
          next.next.single,
          fallbackFrom: map.tiles[next.id]!.anchor,
          fallbackTo: map.tiles[next.next.single]!.anchor,
        );
        // Dos tramos seguidos se unen con la misma dirección, salvo si en
        // esa casilla entra otro camino (una unión).
        final joins = board.tiles.where((t) => t.next.contains(next.id)).length;
        if (joins != 1) continue;
        expect(
          (a.endDirection - b.startDirection).distance,
          lessThan(1e-6),
          reason: 'casilla ${next.id}',
        );
      }
    });

    test('las curvas no se alejan demasiado de la recta', () {
      for (final curve in routes.all) {
        expect(RouteCurves.bulge(curve), lessThan(curve.length * 0.3));
      }
    });
  });
}
