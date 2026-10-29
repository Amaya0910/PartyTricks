import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/widgets/minigames/minigame_result_overlay.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

const _rules = MinigameRules();
const _players = MinigamePlayers(
  names: {'ana': 'Ana', 'beto': 'Beto'},
  colors: {'ana': Colors.red, 'beto': Colors.blue},
);

Duration _ms(int ms) => Duration(milliseconds: ms);

void main() {
  late List<int> sent;

  setUp(() => sent = []);

  Future<void> show(WidgetTester tester, MinigameState minigame) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MinigameView(
            minigame: minigame,
            myId: 'ana',
            players: _players,
            onPlay: sent.add,
          ),
        ),
      ),
    );
  }

  group('Para el Tiempo', () {
    const minigame = MinigameState(
      type: MinigameType.stopwatch,
      round: 1,
      players: ['ana', 'beto'],
      targetMs: 7000,
    );

    testWidgets('explica, muestra el reloj y luego lo esconde', (tester) async {
      await show(tester, minigame);
      expect(find.text('Empieza en'), findsOneWidget);
      expect(find.text('¡Ya!'), findsNothing);

      await tester.pump(_ms(_rules.introMs + 1000));
      expect(find.text('Objetivo: 7 s'), findsOneWidget);
      expect(find.text('1,00 s'), findsOneWidget);

      await tester.pump(_ms(_rules.stopwatchVisibleMs));
      expect(find.text('¿?'), findsOneWidget);
      expect(find.text('El reloj se escondió'), findsOneWidget);
    });

    testWidgets('solo manda el primer toque', (tester) async {
      await show(tester, minigame);
      await tester.pump(_ms(_rules.introMs + 6800));
      await tester.tap(find.text('¡Ya!'));
      await tester.pump();
      expect(sent, [6800]);
      expect(find.text('Paraste en 6,80 s'), findsOneWidget);
      expect(find.text('¡Ya!'), findsNothing);
      expect(find.text('Esperando a los demás (0 de 2)'), findsOneWidget);
    });

    testWidgets('si no toca en 25 segundos, manda que no vale', (tester) async {
      await show(tester, minigame);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump(_ms(_rules.stopwatchLimitMs));
      await tester.pump();
      expect(sent, [MinigameRules.noScore]);
      expect(find.text('Se acabó el tiempo'), findsOneWidget);
    });

    testWidgets('al volver a la partida, si ya jugó, solo espera', (
      tester,
    ) async {
      await show(
        tester,
        const MinigameState(
          type: MinigameType.stopwatch,
          round: 1,
          players: ['ana', 'beto'],
          targetMs: 7000,
          scores: {'ana': 7100},
        ),
      );
      expect(find.text('Paraste en 7,10 s'), findsOneWidget);
      expect(find.text('Esperando a los demás (1 de 2)'), findsOneWidget);
      await tester.pump(_ms(_rules.stopwatchLimitMs * 2));
      expect(sent, isEmpty);
    });
  });

  group('Reacción', () {
    const minigame = MinigameState(
      type: MinigameType.reaction,
      round: 1,
      players: ['ana', 'beto'],
      delayMs: 2000,
    );

    testWidgets('tocar antes del ¡YA! te deja fuera', (tester) async {
      await show(tester, minigame);
      await tester.pump(_ms(_rules.introMs + 500));
      expect(find.text('Prepárate...'), findsOneWidget);
      await tester.tap(find.text('Prepárate...'));
      await tester.pump();
      expect(sent, [MinigameRules.noScore]);
      expect(find.text('¡Te adelantaste! Quedas fuera'), findsOneWidget);
    });

    testWidgets('después del ¡YA! manda cuánto tardó', (tester) async {
      await show(tester, minigame);
      await tester.pump(_ms(_rules.introMs + 2000 + 300));
      expect(find.text('¡YA!'), findsOneWidget);
      await tester.tap(find.text('¡YA!'));
      await tester.pump();
      expect(sent, [300]);
      expect(find.text('Tardaste 300 ms'), findsOneWidget);
    });

    testWidgets('tocar durante la explicación no cuenta', (tester) async {
      await show(tester, minigame);
      await tester.tap(find.text('Empieza en'));
      await tester.pump();
      expect(sent, isEmpty);
    });

    testWidgets('si no toca en 10 segundos después del ¡YA!, no vale', (
      tester,
    ) async {
      await show(tester, minigame);
      await tester.pump(_ms(_rules.introMs + 2000));
      await tester.pump(_ms(_rules.reactionLimitMs));
      await tester.pump();
      expect(sent, [MinigameRules.noScore]);
    });
  });

  group('Globo Bomba', () {
    const minigame = MinigameState(
      type: MinigameType.balloon,
      round: 1,
      players: ['ana', 'beto'],
      capacity: 40,
    );

    testWidgets('en tu turno puedes inflar 1, 2 o 3, una sola vez', (
      tester,
    ) async {
      await show(tester, minigame);
      await tester.pump(_ms(_rules.introMs));
      expect(find.textContaining('Tu turno'), findsOneWidget);
      expect(find.text('Infladas: 0'), findsOneWidget);
      expect(find.textContaining('40'), findsNothing, reason: 'es secreto');

      await tester.tap(find.text('+2'));
      await tester.pump();
      expect(sent, [2]);
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('en el turno de otro solo se mira', (tester) async {
      await show(tester, minigame.copyWith(turn: 1, step: 1, pumps: 4));
      await tester.pump();
      expect(find.text('Turno de Beto'), findsOneWidget);
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('avisa cuando a alguien le revienta', (tester) async {
      await show(tester, minigame.copyWith(turn: 1, step: 3, pumps: 38));
      await tester.pump();
      await show(
        tester,
        minigame.copyWith(turn: 0, step: 4, pumps: 0, out: ['beto']),
      );
      await tester.pump();
      expect(find.text('¡Reventó el globo de Beto!'), findsOneWidget);
      expect(find.text('Fuera: Beto'), findsOneWidget);
    });
  });

  group('Resultado', () {
    Future<void> showResult(WidgetTester tester, MinigameResult? result) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MinigameResultOverlay(
                result: result,
                players: _players,
                coins: 10,
              ),
            ),
          ),
        );

    const result = MinigameResult(
      type: MinigameType.stopwatch,
      round: 1,
      winnerIds: ['beto'],
      targetMs: 7000,
      scores: {'ana': 7300, 'beto': 6700},
      tiebreak: {
        'ana': [2],
        'beto': [5],
      },
    );

    testWidgets('muestra el ganador, el objetivo y el desempate', (
      tester,
    ) async {
      await showResult(tester, null);
      await showResult(tester, result);
      await tester.pump();
      expect(find.text('Ganó Beto'), findsOneWidget);
      expect(find.text('+10 monedas'), findsOneWidget);
      expect(find.text('Objetivo: 7,00 s'), findsOneWidget);
      expect(find.text('Ana: 7,30 s'), findsOneWidget);
      expect(find.text('Empate: se desempató con el dado'), findsOneWidget);

      await tester.pump(MinigameResultOverlay.duration + _ms(100));
      await tester.pump();
      expect(find.text('Ganó Beto'), findsNothing, reason: 'se quita solo');
    });

    testWidgets('al volver a la partida no repite el resultado anterior', (
      tester,
    ) async {
      await showResult(tester, result);
      await tester.pump();
      expect(find.text('Ganó Beto'), findsNothing);
    });

    testWidgets('si nadie tocó a tiempo, nadie gana', (tester) async {
      await showResult(tester, null);
      await showResult(
        tester,
        const MinigameResult(
          type: MinigameType.reaction,
          round: 2,
          winnerIds: [],
          scores: {'ana': MinigameRules.noScore, 'beto': MinigameRules.noScore},
        ),
      );
      await tester.pump();
      expect(find.text('Nadie ganó'), findsOneWidget);
      expect(find.text('Ana: no cuenta'), findsOneWidget);
      await tester.pump(MinigameResultOverlay.duration);
    });
  });
}
