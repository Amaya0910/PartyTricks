import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/board_walk.dart';
import 'package:party_tricks/services/map/map_theme.dart';
import 'package:party_tricks/widgets/map/board_map_view.dart';

/// El primer mapa repartido en una cuadrícula de 7 columnas sobre un mundo
/// de 4000 × 3500: la casilla 0 arriba a la izquierda y la 41 abajo a la
/// derecha, lejos.
final _board = buildDefaultBoard();
final _map = BoardMap(
  size: const Size(4000, 3500),
  tiles: {
    for (var id = 0; id < 42; id++)
      id: MapTile(
        id: id,
        sprite: MapSprite(
          asset: 'plataforma_de_prueba.png',
          rect: Rect.fromCenter(
            center: Offset(300 + (id % 7) * 560.0, 300 + (id ~/ 7) * 560.0),
            width: 100,
            height: 80,
          ),
        ),
      ),
  },
  objects: const [],
  background: 'fondo_de_prueba.png',
);

const _theme = MapTheme(id: 'prueba', directory: 'assets/themes/prueba');
final _plain = LoadedMapTheme(resolveTheme(_theme, const {}));

GameState _state({required int diamond}) => GameState(
  players: const {'a': PlayerState(id: 'a', username: 'Ana')},
  turnOrder: const ['a'],
  totalRounds: 5,
  diamondTileId: diamond,
);

final _indicator = find.byKey(const Key('diamond-indicator'));

/// El indicador con esa etiqueta para lectores de pantalla.
Finder _labeled(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

/// El zoom de la cámara del mapa.
double _zoom(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .entry(0, 0);

void main() {
  Future<void> pumpView(
    WidgetTester tester, {
    required int diamond,
    Size screen = const Size(400, 800),
    LoadedMapTheme? theme,
  }) async {
    tester.view
      ..physicalSize = screen
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BoardMapView(
          map: _map,
          board: _board,
          theme: theme ?? _plain,
          state: _state(diamond: diamond),
          myId: 'a',
          onChooseBranch: (_) {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('si el diamante está lejos, aparece en el borde y apunta hacia '
      'él', (tester) async {
    await pumpView(tester, diamond: 41);

    expect(_indicator, findsOneWidget);
    final box = tester.getRect(_indicator);
    // Entero en la pantalla, del tamaño de celular, y hacia abajo a la
    // derecha (donde está la 41).
    expect(box.left, greaterThanOrEqualTo(0));
    expect(box.right, lessThanOrEqualTo(400));
    expect(box.bottom, lessThanOrEqualTo(800));
    expect(box.width, inInclusiveRange(40, 52));
    expect(box.center.dx > 200 || box.center.dy > 400, isTrue);
    // Dice a cuántas casillas está, por el camino más corto.
    final steps = BoardWalk(_board).between(0, 41).length;
    expect(
      find.descendant(of: _indicator, matching: find.text('$steps')),
      findsOneWidget,
    );
    expect(_labeled('Ver el diamante, a $steps casillas'), findsOneWidget);
  });

  testWidgets('si el diamante se ve, no hay indicador', (tester) async {
    await pumpView(tester, diamond: 1);

    expect(_indicator, findsNothing);
  });

  testWidgets('se actualiza al mover la cámara: si el diamante entra en '
      'pantalla, desaparece', (tester) async {
    await pumpView(tester, diamond: 41);
    expect(_indicator, findsOneWidget);

    // Arrastrar el mapa hacia arriba a la izquierda, como con un dedo, lleva
    // la cámara hacia la esquina del diamante. Mientras se mueve, el
    // indicador se va acomodando.
    final finger = await tester.startGesture(
      tester.getCenter(find.byType(InteractiveViewer)),
    );
    final positions = <Offset>{};
    for (var i = 0; i < 80; i++) {
      await finger.moveBy(const Offset(-60, -60));
      await tester.pump(const Duration(milliseconds: 16));
      if (_indicator.evaluate().isNotEmpty) {
        positions.add(tester.getCenter(_indicator));
      }
    }
    await finger.up();
    // No se espera a que todo se aquiete: el personaje respira sin parar.
    await tester.pump(const Duration(seconds: 1));

    expect(positions.length, greaterThan(1));
    expect(_indicator, findsNothing);
  });

  testWidgets('al tocarlo, la cámara va hasta el diamante sin cambiar el '
      'zoom', (tester) async {
    await pumpView(tester, diamond: 41);
    final zoom = _zoom(tester);

    await tester.tap(_indicator);
    await tester.pump();

    expect(_indicator, findsNothing);
    expect(_zoom(tester), zoom);
  });

  testWidgets('la cámara arranca con el zoom previsto (unas 4 casillas de '
      'ancho) y no vuelve sola al zoom máximo', (tester) async {
    await pumpView(tester, diamond: 41);

    // 400 px de ancho para 1100 px de mundo a lo ancho (4 casillas); más
    // lejos que eso solo hasta que el mapa llene la pantalla (800 / 3500).
    expect(_zoom(tester), closeTo(400 / 1100, 0.0001));
  });

  testWidgets('usa el dibujo del diamante del tema si lo tiene', (
    tester,
  ) async {
    final themed = LoadedMapTheme(
      resolveTheme(_theme, {_theme.pathOf(ThemeAsset.diamond)}),
    );
    await pumpView(tester, diamond: 41, theme: themed);

    final images = tester.widgetList<Image>(
      find.descendant(of: _indicator, matching: find.byType(Image)),
    );
    expect(
      images.map((image) => (image.image as AssetImage).assetName),
      contains(_theme.pathOf(ThemeAsset.diamond)),
    );
  });

  testWidgets('acostado y en tablet queda entero en la pantalla', (
    tester,
  ) async {
    for (final screen in const [Size(800, 400), Size(1024, 1366)]) {
      await pumpView(tester, diamond: 41, screen: screen);
      if (_indicator.evaluate().isEmpty) continue; // En la tablet puede verse.
      final box = tester.getRect(_indicator);
      expect(box.left, greaterThanOrEqualTo(0), reason: '$screen');
      expect(box.top, greaterThanOrEqualTo(0), reason: '$screen');
      expect(box.right, lessThanOrEqualTo(screen.width), reason: '$screen');
      expect(box.bottom, lessThanOrEqualTo(screen.height), reason: '$screen');
      expect(box.width, inInclusiveRange(40, 52), reason: '$screen');
    }
  });

  testWidgets('sin el jugador en la partida no muestra casillas', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BoardMapView(
          map: _map,
          board: _board,
          theme: _plain,
          state: _state(diamond: 41),
          myId: 'espectador',
          onChooseBranch: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(_labeled('Ver el diamante'), findsOneWidget);
  });
}
