import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/screens/results_screen.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';

GameState _game({bool tie = false}) {
  return GameState(
    players: {
      'a': const PlayerState(
        id: 'a',
        username: 'Ana',
        diamonds: 3,
        coins: 25,
        diceRolled: 9,
        diceTotal: 31,
        purchases: 2,
        itemsUsed: 1,
        minigamesWon: 2,
      ),
      'b': PlayerState(
        id: 'b',
        username: 'Beto',
        diamonds: tie ? 5 : 1,
        coins: 4,
        negativeTiles: 6,
      ),
      'c': const PlayerState(id: 'c', username: 'Caro'),
    },
    turnOrder: const ['b', 'a', 'c'],
    totalRounds: 5,
    round: 5,
    diamondTileId: 1,
    phase: GamePhase.finished,
  );
}

Future<void> pump(
  WidgetTester tester,
  GameState game, {
  String myId = 'a',
  VoidCallback? onExit,
  Size screen = const Size(400, 2400),
}) async {
  tester.view
    ..physicalSize = screen
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ResultsScreen(game: game, myId: myId, onExit: onExit ?? () {}),
    ),
  );
}

void main() {
  testWidgets('muestra el ganador, la clasificación y tus premios', (
    tester,
  ) async {
    final game = _game();
    final results = const MatchResultsBuilder().build(game);
    await pump(tester, game);

    expect(find.text('¡Ganaste!'), findsOneWidget);
    expect(find.text('Partida de 5 rondas'), findsOneWidget);
    expect(find.text('Quedaste en el puesto 1'), findsOneWidget);
    expect(find.text('+${results.of('a')!.experience} XP'), findsNWidgets(2));
    // Clasificación completa, con tu fila marcada.
    expect(find.text('Ana (tú)'), findsOneWidget);
    // Beto sale en la clasificación y como ganador de "Peor suerte".
    expect(find.text('Beto'), findsNWidgets(2));
    expect(find.text('Caro'), findsOneWidget);
    // Diamantes finales, con quién los ganó.
    expect(find.text('Peor suerte'), findsOneWidget);
    expect(find.text('Más comprador'), findsOneWidget);
    expect(find.text('Nadie'), findsNothing);
    // Tu partida.
    expect(find.text('Dados lanzados'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('2 de 5'), findsOneWidget);
  });

  testWidgets('si gana otro lo dice con su nombre', (tester) async {
    final game = _game();
    final caro = const MatchResultsBuilder().build(game).of('c')!;
    await pump(tester, game, myId: 'c');

    expect(find.text('¡Ganó Ana!'), findsOneWidget);
    expect(find.text('Quedaste en el puesto 3'), findsOneWidget);
    expect(find.text('+${caro.experience} XP'), findsNWidgets(2));
  });

  testWidgets('en un empate nombra a los ganadores', (tester) async {
    await pump(tester, _game(tie: true), myId: 'c');

    expect(find.textContaining('¡Empate! Ganan'), findsOneWidget);
    expect(find.textContaining('Ana'), findsWidgets);
  });

  testWidgets('el botón vuelve al inicio', (tester) async {
    var exited = false;
    await pump(tester, _game(), onExit: () => exited = true);

    await tester.tap(find.text('Volver al inicio'));
    expect(exited, isTrue);
  });

  testWidgets('en un teléfono pequeño se puede recorrer sin salirse', (
    tester,
  ) async {
    await pump(tester, _game(), screen: const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text('Volver al inicio'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(find.text('Ítems usados'), findsOneWidget);
  });
}
