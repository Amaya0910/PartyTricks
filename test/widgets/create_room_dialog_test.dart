import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/remote_map_config.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/create_room_dialog.dart';

import '../services/map/fake_maps.dart';

void main() {
  Future<List<RoomSettings?>> openDialog(
    WidgetTester tester, {
    List<MapDefinition> maps = MapCatalog.all,
    RemoteMapConfig? remote,
    ValueNotifier<RemoteMapConfig>? liveRemote,
    Random? random,
  }) async {
    final live = liveRemote ?? ValueNotifier(remote ?? allEnabled(maps));
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
                    builder: (_) => ValueListenableBuilder(
                      valueListenable: live,
                      builder: (_, remote, _) => CreateRoomDialog(
                        remote: remote,
                        maps: maps,
                        random: random,
                      ),
                    ),
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

  testWidgets('con el catálogo real y Firebase sin encenderlos, solo se ve '
      'Mapa 1', (tester) async {
    final results = await openDialog(
      tester,
      remote: RemoteMapConfig.unavailable,
    );

    await tester.tap(find.byKey(const Key('choose-map')));
    await tester.pumpAndSettle();
    expect(find.text('Mundo Dulce'), findsNothing);
    await tester.tap(find.text('Jugar en Mapa 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(results.single!.mapId, 'mapa_01');
  });

  testWidgets('un mapa oculto no se muestra ni aunque sea el primero', (
    tester,
  ) async {
    final results = await openDialog(tester, maps: [hiddenMap, ...fakeMaps(2)]);

    expect(find.text('Oculto'), findsNothing);
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(results.single!.mapId, 'mapa_01');
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

  group('mapa aleatorio', () {
    testWidgets('con el interruptor, la sala sale con uno de los mapas '
        'disponibles', (tester) async {
      final results = await openDialog(
        tester,
        maps: fakeMaps(3),
        random: _FixedRandom(2),
      );

      await tester.tap(find.byKey(const Key('random-map')));
      await tester.pumpAndSettle();
      expect(find.text('Aleatorio'), findsOneWidget);
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      // El sorteo da la posición 2 de [Mapa 1, Prueba 2, Prueba 3].
      expect(results.single!.mapId, 'mapa_prueba_3');
    });

    testWidgets('sin el interruptor se juega el mapa elegido, no uno al azar', (
      tester,
    ) async {
      final results = await openDialog(
        tester,
        maps: fakeMaps(3),
        random: _FixedRandom(2),
      );

      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(results.single!.mapId, 'mapa_01');
    });

    testWidgets('elegir un mapa a mano apaga lo aleatorio', (tester) async {
      final results = await openDialog(
        tester,
        maps: fakeMaps(3),
        random: _FixedRandom(2),
      );

      await tester.tap(find.byKey(const Key('random-map')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choose-map')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('map-thumb-mapa_prueba_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jugar en Prueba 2'));
      await tester.pumpAndSettle();

      expect(find.text('Aleatorio'), findsNothing);
      expect(
        tester.widget<Switch>(find.byKey(const Key('random-map'))).value,
        isFalse,
      );
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(results.single!.mapId, 'mapa_prueba_2');
    });

    testWidgets('con un solo mapa disponible no se ofrece', (tester) async {
      await openDialog(tester, remote: RemoteMapConfig.unavailable);

      expect(find.byKey(const Key('random-map')), findsNothing);
    });
  });

  group('interruptor remoto', () {
    final dulces = enabled(MapCatalog.mapaDulces);

    testWidgets('Mundo Dulce encendido se puede elegir y llega a la sala', (
      tester,
    ) async {
      final results = await openDialog(
        tester,
        maps: [MapCatalog.mapa01, dulces],
        remote: const RemoteMapConfig(enabledIds: {'mapa_dulces'}),
      );

      await tester.tap(find.byKey(const Key('choose-map')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('map-thumb-mapa_dulces')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jugar en Mundo Dulce'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(results.single!.mapId, 'mapa_dulces');
    });

    testWidgets('Firebase caído: solo mapa_01', (tester) async {
      final results = await openDialog(
        tester,
        maps: [MapCatalog.mapa01, dulces],
        remote: RemoteMapConfig.unavailable,
      );

      await tester.tap(find.byKey(const Key('choose-map')));
      await tester.pumpAndSettle();
      expect(find.text('Mundo Dulce'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(results.single!.mapId, 'mapa_01');
    });

    testWidgets('si lo apagan con el diálogo abierto vuelve a mapa_01', (
      tester,
    ) async {
      final live = ValueNotifier(
        const RemoteMapConfig(enabledIds: {'mapa_dulces'}),
      );
      addTearDown(live.dispose);
      final results = await openDialog(
        tester,
        maps: [MapCatalog.mapa01, dulces],
        liveRemote: live,
      );
      await tester.tap(find.byKey(const Key('choose-map')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('map-thumb-mapa_dulces')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jugar en Mundo Dulce'));
      await tester.pumpAndSettle();
      expect(find.text('Mundo Dulce'), findsOneWidget);

      live.value = RemoteMapConfig.unavailable;
      await tester.pumpAndSettle();

      expect(find.text('Mundo Dulce'), findsNothing);
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();
      expect(results.single!.mapId, 'mapa_01');
    });
  });
}

/// Un `Random` que siempre da el mismo número.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final int value;

  @override
  int nextInt(int max) => value;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}
