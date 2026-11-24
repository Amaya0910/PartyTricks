import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/map_theme.dart';
import 'package:party_tricks/widgets/map/board_map_view.dart';

import '../services/game_engine/fake_random_source.dart';

/// El primer mapa dibujado de forma que se note por dónde camina cada uno:
/// el camino principal en la fila de arriba (y = 300) y los dos atajos
/// (32…41) en la de abajo (y = 1500).
final _board = buildDefaultBoard();
const _shortcutRow = 1500.0;

final _map = BoardMap(
  size: const Size(4400, 1800),
  tiles: {
    for (var id = 0; id < 42; id++)
      id: MapTile(
        id: id,
        sprite: MapSprite(
          asset: 'plataforma_de_prueba.png',
          rect: Rect.fromCenter(
            center: id < 32
                ? Offset(200 + id * 130.0, 300)
                : Offset(200 + id * 100.0, _shortcutRow),
            width: 100,
            height: 80,
          ),
        ),
      ),
  },
  objects: const [],
  background: 'fondo_de_prueba.png',
);

final _theme = LoadedMapTheme(resolveTheme(MapThemeCatalog.classic, const {}));

Widget _view(GameState state) => MaterialApp(
  home: BoardMapView(
    map: _map,
    board: _board,
    theme: _theme,
    state: state,
    myId: 'a',
    onChooseBranch: (_) {},
  ),
);

/// Dónde están los pies del personaje ahora, en píxeles del mundo. El
/// personaje de Ana está dentro de su `Positioned` (el de más afuera).
Offset _feet(WidgetTester tester) {
  final box = tester.widget<Positioned>(
    find
        .descendant(
          of: find.byKey(const ValueKey('a')),
          matching: find.byType(Positioned),
        )
        .first,
  );
  // Los pies no están en el borde de abajo del lienzo, sino un poco arriba.
  const feetLine = (697 + 200) / 968;
  return Offset(box.left! + box.width! / 2, box.top! + box.height! * feetLine);
}

void main() {
  testWidgets('elige el camino principal con pasos de sobra y camina por él, '
      'no por el atajo', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Ana se detuvo en la bifurcación 13 con 11 pasos por dar (por ejemplo,
    // con el dado de 12) y elige el camino principal. La 17 es una tienda:
    // se detiene ahí de paso y, al seguir, termina en la 24.
    final before = GameState(
      players: const {'a': PlayerState(id: 'a', username: 'Ana', position: 13)},
      turnOrder: const ['a'],
      totalRounds: 5,
      diamondTileId: 35,
      phase: GamePhase.choosingBranch,
      stepsLeft: 11,
    );
    final engine = GameEngine(
      board: _board,
      random: FakeRandomSource(const []),
    );
    final atShop = engine.apply(before, const ChooseBranch('a', 0));
    expect(atShop.players['a']!.position, 17);
    final after = engine.apply(atShop, const LeaveShop('a'));
    expect(after.players['a']!.position, 24);

    var lowest = 0.0;
    var highestX = 0.0;
    Future<void> walkFrames(int frames) async {
      for (var frame = 0; frame < frames; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        final feet = _feet(tester);
        if (feet.dy > lowest) lowest = feet.dy;
        if (feet.dx > highestX) highestX = feet.dx;
      }
    }

    await tester.pumpWidget(_view(before));
    await tester.pumpWidget(_view(atShop));
    await walkFrames(60);
    expect(_feet(tester), _map.tiles[17]!.anchor);

    await tester.pumpWidget(_view(after));
    await walkFrames(80);

    // Nunca bajó a la fila de los atajos y llegó a la 24.
    expect(lowest, lessThan(_shortcutRow / 2));
    expect(_feet(tester), _map.tiles[24]!.anchor);
    // Pasó por la 22, la última del camino principal antes de juntarse.
    expect(highestX, greaterThanOrEqualTo(_map.tiles[22]!.anchor.dx));
  });

  testWidgets('si elige el atajo, camina por el atajo', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final before = GameState(
      players: const {'a': PlayerState(id: 'a', username: 'Ana', position: 13)},
      turnOrder: const ['a'],
      totalRounds: 5,
      diamondTileId: 35,
      phase: GamePhase.choosingBranch,
      stepsLeft: 7,
    );
    final engine = GameEngine(
      board: _board,
      random: FakeRandomSource(const []),
    );
    final after = engine.apply(before, const ChooseBranch('a', 1));

    await tester.pumpWidget(_view(before));
    await tester.pumpWidget(_view(after));

    var lowest = 0.0;
    for (var frame = 0; frame < 80; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      final feet = _feet(tester);
      if (feet.dy > lowest) lowest = feet.dy;
    }

    expect(lowest, greaterThan(_shortcutRow - 100));
    expect(_feet(tester), _map.tiles[24]!.anchor);
  });
}
