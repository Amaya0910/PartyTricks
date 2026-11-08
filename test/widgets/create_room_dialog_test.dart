import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/create_room_dialog.dart';

import '../services/map/fake_maps.dart';

void main() {
  Future<List<RoomSettings?>> openDialog(
    WidgetTester tester, {
    List<MapDefinition> maps = MapCatalog.all,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final results = <RoomSettings?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async => results.add(
                  await showBlurredDialog<RoomSettings>(
                    context,
                    builder: (_) => CreateRoomDialog(maps: maps),
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

  testWidgets('por defecto la sala es de mapa_01', (tester) async {
    final results = await openDialog(tester);

    expect(find.text('Mapa 1'), findsOneWidget);
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(results.single!.mapId, 'mapa_01');
  });

  testWidgets('el mapa elegido en el selector llega a RoomSettings', (
    tester,
  ) async {
    final results = await openDialog(tester, maps: fakeMaps(3));

    await tester.tap(find.byKey(const Key('choose-map')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-thumb-mapa_prueba_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jugar en Prueba 3'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('choose-map')),
        matching: find.text('Prueba 3'),
      ),
      findsWidgets,
    );
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    final settings = results.single!;
    expect(settings.mapId, 'mapa_prueba_3');
    // Lo demás no cambia al elegir mapa.
    expect(settings.maxPlayers, 3);
    expect(settings.rounds, 10);
  });

  testWidgets('volver del selector sin elegir deja el mapa que estaba', (
    tester,
  ) async {
    final results = await openDialog(tester, maps: fakeMaps(3));

    await tester.tap(find.byKey(const Key('choose-map')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(results.single!.mapId, 'mapa_01');
  });
}
