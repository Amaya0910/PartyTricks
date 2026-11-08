import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/map_providers.dart';
import 'package:party_tricks/services/map/map_theme.dart';
import 'package:party_tricks/widgets/map/board_map_view.dart';
import 'package:party_tricks/widgets/map/map_scenery.dart';

/// Salida (0) → 1 → 2 → 3 → salida, con bifurcación en la 1 (atajo 1 → 3).
final _board = BoardLayout(const [
  BoardTile(id: 0, type: TileType.start, next: [1]),
  BoardTile(id: 1, type: TileType.positive, next: [2, 3]),
  BoardTile(id: 2, type: TileType.negative, next: [3]),
  BoardTile(id: 3, type: TileType.special, next: [0]),
]);

final _map = BoardMap(
  size: const Size(1600, 1600),
  tiles: {
    for (final (id, offset) in const [
      (0, Offset(200, 200)),
      (1, Offset(800, 200)),
      (2, Offset(800, 800)),
      (3, Offset(200, 800)),
    ])
      id: MapTile(
        id: id,
        sprite: MapSprite(
          asset: 'plataforma_de_prueba.png',
          rect: Rect.fromCenter(center: offset, width: 384, height: 320),
        ),
      ),
  },
  objects: const [],
  background: 'fondo_de_prueba.png',
);

const _theme = MapTheme(id: 'prueba', directory: 'assets/themes/prueba');

/// Un tema con todo dibujado, salvo lo que se quite en [without].
LoadedMapTheme _loaded({Set<ThemeAsset> without = const {}}) => LoadedMapTheme(
  resolveTheme(_theme, {
    for (final asset in ThemeAsset.values)
      if (!without.contains(asset)) _theme.pathOf(asset),
  }),
);

/// Los assets de las imágenes en pantalla.
Set<String> _shownAssets(WidgetTester tester) => {
  for (final image in tester.widgetList<Image>(find.byType(Image)))
    if (image.image case final AssetImage asset) asset.assetName,
};

void main() {
  testWidgets('las marcas salen del tema del mapa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: MapScenery(map: _map, board: _board, theme: _loaded()),
        ),
      ),
    );

    final shown = _shownAssets(tester);
    expect(
      shown,
      containsAll([
        _theme.pathOf(ThemeAsset.startMark),
        _theme.pathOf(ThemeAsset.positiveMark),
        _theme.pathOf(ThemeAsset.negativeMark),
        _theme.pathOf(ThemeAsset.specialMark),
        // La 1 es bifurcación: lleva las dos.
        _theme.pathOf(ThemeAsset.forkMark),
      ]),
    );
    expect(shown.where((a) => a.contains('/assets/images/')), isEmpty);
  });

  testWidgets('sin textura ni marcas, el mapa se dibuja igual', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: MapScenery(
            map: _map,
            board: _board,
            theme: LoadedMapTheme(resolveTheme(_theme, const {})),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_shownAssets(tester).where((a) => a.contains('marca_')), isEmpty);
  });

  group('diamante y trampas', () {
    Future<void> pumpView(WidgetTester tester, LoadedMapTheme theme) async {
      tester.view
        ..physicalSize = const Size(800, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: BoardMapView(
            map: _map,
            board: _board,
            theme: theme,
            state: const GameState(
              players: {'a': PlayerState(id: 'a', username: 'Ana')},
              turnOrder: ['a'],
              totalRounds: 5,
              diamondTileId: 2,
              traps: {3: 'a'},
            ),
            myId: 'a',
            onChooseBranch: (_) {},
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('usan los dibujos del tema', (tester) async {
      await pumpView(tester, _loaded());

      final shown = _shownAssets(tester);
      expect(shown, contains(_theme.pathOf(ThemeAsset.diamond)));
      expect(shown, contains(_theme.pathOf(ThemeAsset.trap)));
      // Esos archivos no existen en las pruebas: si un dibujo no carga,
      // también se ve el ícono, sin romperse.
      expect(tester.takeException(), isNull);
    });

    testWidgets('si el tema no los tiene, se ven los íconos', (tester) async {
      await pumpView(
        tester,
        _loaded(without: {ThemeAsset.diamond, ThemeAsset.trap}),
      );

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.diamond), findsOneWidget);
      expect(find.byIcon(Icons.dangerous), findsOneWidget);
    });
  });

  testWidgets('el tema de mapa_01 carga con la textura y sin respaldos', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final loaded = await tester.runAsync(
      () => container.read(mapThemeProvider('mapa_01').future),
    );

    expect(loaded!.theme, same(MapThemeCatalog.classic));
    expect(loaded.pathTexture, isNotNull);
    expect(loaded.resolved.fallbacks, isEmpty);
    expect(
      loaded.resolved.markFor(TileType.negative),
      MapThemeCatalog.classic.pathOf(ThemeAsset.negativeMark),
    );
  });
}
