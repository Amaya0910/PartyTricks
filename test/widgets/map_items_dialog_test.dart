import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'package:party_tricks/widgets/map_items_dialog.dart';

/// Ana tiene el turno. En el mapa real la 2 es positiva y la 36 tienda.
GameState game({
  required GamePhase phase,
  int position = 36,
  int coins = 6,
  Map<ShopItem, int> inventory = const {},
}) {
  return GameState(
    players: {
      'a': PlayerState(
        id: 'a',
        username: 'Ana',
        position: position,
        coins: coins,
        inventory: inventory,
      ),
      'b': const PlayerState(id: 'b', username: 'Beto'),
    },
    turnOrder: const ['a', 'b'],
    totalRounds: 5,
    diamondTileId: 41,
    phase: phase,
  );
}

Future<List<GameAction>> pumpDialog(
  WidgetTester tester, {
  required GameState state,
  required ItemsMode mode,
  String myId = 'a',
  Size screen = const Size(400, 2000),
}) async {
  tester.view
    ..physicalSize = screen
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final sent = <GameAction>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gameProvider('sala').overrideWith((ref) => Stream.value(state)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MapItemsDialog(
            roomId: 'sala',
            myId: myId,
            mode: mode,
            onAction: sent.add,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return sent;
}

FilledButton buttonOf(WidgetTester tester, String title) {
  final tile = find.ancestor(
    of: find.textContaining(title),
    matching: find.byType(ListTile),
  );
  return tester.widget<FilledButton>(
    find.descendant(of: tile, matching: find.byType(FilledButton)),
  );
}

void main() {
  testWidgets('la tienda muestra los precios y compra lo que alcanza', (
    tester,
  ) async {
    final sent = await pumpDialog(
      tester,
      state: game(phase: GamePhase.shopping),
      mode: ItemsMode.shop,
    );

    expect(find.text('Tienda'), findsOneWidget);
    for (final item in ShopItem.values) {
      expect(find.text(item.title), findsOneWidget);
    }
    // Con 6 monedas no alcanza para el dado de 9 ni el diamante doble.
    expect(buttonOf(tester, 'Dado extra de 9').onPressed, isNull);
    expect(buttonOf(tester, 'Diamante doble').onPressed, isNull);
    expect(find.text('No te alcanzan las monedas'), findsNWidgets(2));

    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Escudo'),
          matching: find.byType(ListTile),
        ),
        matching: find.byType(FilledButton),
      ),
    );
    expect(sent, hasLength(1));
    final buy = sent.single as BuyItem;
    expect(buy.playerId, 'a');
    expect(buy.item, ShopItem.shield);
  });

  testWidgets('en un teléfono pequeño la tienda hace scroll sin salirse', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      state: game(phase: GamePhase.shopping),
      mode: ItemsMode.shop,
      screen: const Size(360, 640),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsOneWidget);
  });

  testWidgets('la mochila deja usar los activos y no los pasivos', (
    tester,
  ) async {
    final sent = await pumpDialog(
      tester,
      state: game(
        phase: GamePhase.rolling,
        position: 2,
        inventory: {ShopItem.trap: 1, ShopItem.shield: 2},
      ),
      mode: ItemsMode.backpack,
    );

    expect(find.text('Mochila'), findsOneWidget);
    expect(find.text('Trampa (x1)'), findsOneWidget);
    expect(find.text('Escudo (x2)'), findsOneWidget);
    // Lo que no tiene no sale.
    expect(find.text('Impulso'), findsNothing);
    expect(buttonOf(tester, 'Escudo').onPressed, isNull);

    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Trampa (x1)'),
          matching: find.byType(ListTile),
        ),
        matching: find.byType(FilledButton),
      ),
    );
    expect((sent.single as UseItem).item, ShopItem.trap);
  });

  testWidgets('fuera de tu turno la mochila solo se mira', (tester) async {
    // Le toca a Ana; Beto mira su mochila.
    await pumpDialog(
      tester,
      state: game(phase: GamePhase.rolling).withPlayer(
        const PlayerState(
          id: 'b',
          username: 'Beto',
          inventory: {ShopItem.extraDie6: 1},
        ),
      ),
      mode: ItemsMode.backpack,
      myId: 'b',
    );

    expect(find.text('Dado extra de 6 (x1)'), findsOneWidget);
    expect(buttonOf(tester, 'Dado extra de 6').onPressed, isNull);
    expect(find.text('Úsalo en tu turno, antes del dado'), findsOneWidget);
  });

  testWidgets('la mochila vacía lo dice', (tester) async {
    await pumpDialog(
      tester,
      state: game(phase: GamePhase.rolling),
      mode: ItemsMode.backpack,
    );

    expect(
      find.text('Tu mochila está vacía. Compra ítems en las tiendas del mapa.'),
      findsOneWidget,
    );
  });

  testWidgets('la trampa no se puede usar en la tienda', (tester) async {
    await pumpDialog(
      tester,
      state: game(phase: GamePhase.rolling, inventory: {ShopItem.trap: 1}),
      mode: ItemsMode.backpack,
    );

    expect(buttonOf(tester, 'Trampa').onPressed, isNull);
    expect(find.text('No se puede poner en esta casilla'), findsOneWidget);
  });
}
