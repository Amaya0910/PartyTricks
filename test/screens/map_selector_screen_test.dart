import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/screens/map_selector_screen.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_theme.dart';
import 'package:party_tricks/widgets/map/map_preview_image.dart';

import '../services/map/fake_maps.dart';

void main() {
  /// Abre el selector desde un botón y guarda lo que devuelve.
  Future<List<String?>> openSelector(
    WidgetTester tester, {
    required Size size,
    List<MapDefinition> maps = MapCatalog.all,
    String selectedId = 'mapa_01',
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final results = <String?>[];
    // Empieza de cero aunque el selector haya quedado abierto antes.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async => results.add(
                  await MapSelectorScreen.show(
                    context,
                    selectedId: selectedId,
                    rounds: 10,
                    players: 3,
                    maps: maps,
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('muestra la información de mapa_01 en un celular', (
    tester,
  ) async {
    await openSelector(tester, size: const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text('Mapa 1'), findsOneWidget);
    expect(find.text(MapCatalog.mapa01.description), findsOneWidget);
    expect(find.text('42 casillas · Pequeño'), findsOneWidget);
    expect(find.text('2 atajos'), findsOneWidget);
    expect(find.text('2 tiendas'), findsOneWidget);
    // 10 rondas × (3 × 20 s + 40 s) = 1000 s ≈ 17 min.
    expect(find.text('≈ 17 min (10 rondas)'), findsOneWidget);
    expect(find.text('2–6 jugadores'), findsOneWidget);
    expect(find.text('Todas las versiones'), findsOneWidget);
    expect(find.byType(MapPreviewImage), findsOneWidget);
    // Con un solo mapa no hace falta la lista.
    expect(find.byKey(const Key('map-list')), findsNothing);
  });

  testWidgets('elegir devuelve el id del mapa; volver devuelve null', (
    tester,
  ) async {
    final results = await openSelector(tester, size: const Size(360, 640));

    await tester.tap(find.text('Jugar en Mapa 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(results, ['mapa_01', null]);
  });

  testWidgets('con 6 mapas la lista se desliza y se puede elegir el último', (
    tester,
  ) async {
    final results = await openSelector(
      tester,
      size: const Size(360, 640),
      maps: fakeMaps(6),
    );

    expect(find.byKey(const Key('map-list')), findsOneWidget);
    final last = find.byKey(const ValueKey('map-thumb-mapa_prueba_6'));
    await tester.scrollUntilVisible(
      last,
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('map-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(last);
    await tester.pumpAndSettle();

    expect(find.text('Mapa de prueba 6'), findsOneWidget);
    expect(
      find.text(
        'Requiere la app actualizada (protocolo ${AppProtocol.current})',
      ),
      findsOneWidget,
    );
    // Sin preview.png se ve el recuadro de reemplazo, sin romperse.
    expect(find.byIcon(Icons.map), findsWidgets);

    await tester.tap(find.text('Jugar en Prueba 6'));
    await tester.pumpAndSettle();
    expect(results, ['mapa_prueba_6']);
  });

  testWidgets('en una tablet muestra el detalle y la lista lado a lado', (
    tester,
  ) async {
    await openSelector(
      tester,
      size: const Size(1024, 768),
      maps: fakeMaps(5),
      selectedId: 'mapa_prueba_3',
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Mapa de prueba 3'), findsOneWidget);
    final list = tester.getRect(find.byKey(const Key('map-list')));
    expect(list.left, greaterThan(1024 / 2));
    expect(list.height, greaterThan(list.width));
  });

  testWidgets('no se desborda en pantallas pequeñas ni acostadas', (
    tester,
  ) async {
    for (final size in const [
      Size(320, 480),
      Size(640, 360),
      Size(800, 1280),
    ]) {
      await openSelector(tester, size: size, maps: fakeMaps(7));
      expect(tester.takeException(), isNull, reason: 'Pantalla $size');
    }
  });

  testWidgets('si el id no existe empieza en el primer mapa', (tester) async {
    await openSelector(
      tester,
      size: const Size(360, 640),
      selectedId: 'no_existe',
    );

    expect(find.text('Mapa 1'), findsOneWidget);
  });

  testWidgets('el selector toma el color del tema del mapa elegido', (
    tester,
  ) async {
    await openSelector(tester, size: const Size(360, 640), maps: fakeMaps(3));
    Color buttonColor() => tester
        .widget<FilledButton>(find.byKey(const Key('choose-map-button')))
        .style!
        .backgroundColor!
        .resolve(const {})!;
    final classicColor = buttonColor();

    await tester.tap(find.byKey(const ValueKey('map-thumb-mapa_prueba_2')));
    await tester.pumpAndSettle();

    expect(buttonColor(), candyTheme.colors.accent);
    expect(classicColor, MapThemeCatalog.classic.colors.accent);
    final thumb = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('map-thumb-mapa_prueba_2')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final border = (thumb.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, candyTheme.colors.accent);
  });
}
