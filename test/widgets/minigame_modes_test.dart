import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/map/map_assets.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/coin_rain_game.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_result_overlay.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

const _rules = MinigameRules();
const _ids = ['ana', 'beto'];
const _players = MinigamePlayers(
  names: {'ana': 'Ana', 'beto': 'Beto', 'caro': 'Caro'},
  colors: {'ana': Colors.red, 'beto': Colors.blue, 'caro': Colors.green},
);

/// Semilla fija: todos los minijuegos sacan siempre lo mismo.
const _seed = 4242;

Duration _ms(int ms) => Duration(milliseconds: ms);

void main() {
  late List<int> sent;

  setUp(() => sent = []);

  Widget app(MinigameState minigame, String myId) {
    return MaterialApp(
      home: Scaffold(
        body: MinigameView(
          minigame: minigame,
          myId: myId,
          players: _players,
          onPlay: sent.add,
        ),
      ),
    );
  }

  Future<void> show(
    WidgetTester tester,
    MinigameState minigame, {
    String myId = 'ana',
  }) {
    tester.view.physicalSize = const Size(412, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(app(minigame, myId));
  }

  /// Avanza de a poco, como los cuadros de verdad.
  Future<void> run(WidgetTester tester, int ms, {int step = 100}) async {
    for (var t = 0; t < ms; t += step) {
      await tester.pump(_ms(step));
    }
  }

  MinigameState solo(MinigameType type) =>
      MinigameState(type: type, round: 1, players: _ids, seed: _seed);

  testWidgets('quien no juega los de puntaje solo mira', (tester) async {
    const types = [
      MinigameType.rhythm,
      MinigameType.diceMemory,
      MinigameType.coinRain,
      MinigameType.colorTrap,
      MinigameType.quickMath,
      MinigameType.safeLock,
    ];
    for (final type in types) {
      await show(tester, solo(type), myId: 'caro');
      expect(
        find.text('Este minijuego lo ves desde fuera.'),
        findsOneWidget,
        reason: type.name,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('si ya jugó y vuelve a la partida, solo espera', (tester) async {
    await show(
      tester,
      solo(MinigameType.coinRain).copyWith(scores: {'ana': 12}),
    );
    expect(find.text('¡Cazaste 12 puntos!'), findsOneWidget);
    expect(find.text('Esperando a los demás (1 de 2)'), findsOneWidget);
    await run(tester, _rules.coinRainMs + _rules.introMs, step: 1000);
    expect(sent, isEmpty);
    await run(tester, 1000);
  });

  group('Pulso Perfecto', () {
    final beat = rhythmBeatMs(
      _seed,
      min: _rules.minBeatMs,
      max: _rules.maxBeatMs,
    );
    final arena = find.byIcon(Icons.favorite_rounded).last;

    testWidgets('sigue el ritmo y manda cuánto se desvió', (tester) async {
      await show(tester, solo(MinigameType.rhythm));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      expect(find.text('Mira el ritmo...'), findsOneWidget);

      await tester.pump(_ms(beat * _rules.rhythmDemoBeats));
      for (var tap = 0; tap < _rules.rhythmTaps; tap++) {
        await tester.tap(arena, warnIfMissed: false);
        await tester.pump(_ms(beat));
      }
      expect(sent, [0], reason: 'tocó exacto todas las veces');
      expect(find.text('Te desviaste 0 ms'), findsOneWidget);
    });

    testWidgets('califica cada toque', (tester) async {
      await show(tester, solo(MinigameType.rhythm));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump(_ms(beat * _rules.rhythmDemoBeats));
      await tester.tap(arena, warnIfMissed: false);
      await tester.pump(_ms(beat + 60));
      expect(find.text('¡Perfecto!'), findsOneWidget);
      await tester.tap(arena, warnIfMissed: false);
      await tester.pump();
      expect(find.text('¡Muy bien!'), findsOneWidget);
    });

    testWidgets('mientras se mira el ritmo, tocar no cuenta', (tester) async {
      await show(tester, solo(MinigameType.rhythm));
      await tester.pump(_ms(_rules.introMs + 100));
      await tester.tap(arena, warnIfMissed: false);
      await tester.pump();
      expect(find.text('Mira el ritmo...'), findsOneWidget);
      expect(sent, isEmpty);
    });

    testWidgets('si no termina a tiempo, no cuenta', (tester) async {
      await show(tester, solo(MinigameType.rhythm));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump(_ms(_rules.rhythmLimitMs));
      await tester.pump();
      expect(sent, [MinigameRules.noScore]);
      expect(find.text('Se acabó el tiempo'), findsOneWidget);
    });
  });

  group('Memoria de Dados', () {
    final faces = diceMemoryFaces(_seed, _rules.diceMemoryMax);
    final buttons = find.byWidgetPredicate(
      (widget) => widget is Image && (widget.width ?? 0) > 40,
    );
    Finder die(int face) => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          (widget.width ?? 0) > 40 &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == MapAssets.dice(face),
    );

    Future<void> untilRepeat(WidgetTester tester, int length) async {
      final dieMs = 640 - (length - _rules.diceMemoryStart) * 45;
      await run(tester, length * dieMs + 300, step: 50);
    }

    testWidgets('al acertar la fila, crece', (tester) async {
      await show(tester, solo(MinigameType.diceMemory));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      expect(find.text('¡Memoriza!'), findsOneWidget);
      expect(find.text('Fila de 3'), findsOneWidget);
      expect(buttons, findsOneWidget, reason: 'se ve un dado a la vez');

      await untilRepeat(tester, 3);
      expect(buttons, findsNWidgets(6));
      for (final face in faces.take(3)) {
        await tester.tap(die(face));
        await tester.pump();
      }
      expect(find.text('¡Bien! Uno más'), findsOneWidget);
      await run(tester, 700);
      expect(find.text('Fila de 4'), findsOneWidget);
      expect(find.text('¡Memoriza!'), findsOneWidget);
    });

    testWidgets('al fallar, vale la última fila que acertó', (tester) async {
      await show(tester, solo(MinigameType.diceMemory));
      await tester.pump(_ms(_rules.introMs));
      await untilRepeat(tester, 3);
      for (final face in faces.take(3)) {
        await tester.tap(die(face));
        await tester.pump();
      }
      await run(tester, 700);
      await untilRepeat(tester, 4);

      final wrong = faces[0] == 1 ? 2 : 1;
      await tester.tap(die(wrong));
      await tester.pump();
      expect(find.text('Era este:'), findsOneWidget);
      expect(sent, isEmpty, reason: 'primero se ve cuál era');

      await run(tester, 1400);
      expect(sent, [3]);
      expect(find.text('Llegaste a 3 dados'), findsOneWidget);
    });

    testWidgets('fallar la primera vale 0', (tester) async {
      await show(tester, solo(MinigameType.diceMemory));
      await tester.pump(_ms(_rules.introMs));
      await untilRepeat(tester, 3);
      await tester.tap(die(faces[0] == 1 ? 2 : 1));
      await tester.pump();
      await run(tester, 1400);
      expect(sent, [0]);
      expect(find.text('No repetiste ninguna fila'), findsOneWidget);
    });

    testWidgets('al acabarse el tiempo vale lo que lleve', (tester) async {
      await show(tester, solo(MinigameType.diceMemory));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump(_ms(_rules.diceMemoryLimitMs));
      await tester.pump();
      expect(sent, [0]);
    });
  });

  group('Cazamonedas', () {
    final script = coinRainScript(_seed, _rules.coinRainMs);
    final coin = script.firstWhere((item) => item.kind == FallingKind.coin);
    final arena = find.descendant(
      of: find.byType(CoinRainGame),
      matching: find.byType(Listener),
    );

    /// Avanza hasta que [item] va por la mitad y lo toca.
    Future<void> catchItem(WidgetTester tester, FallingItem item) async {
      await tester.pump(_ms(item.startMs + item.fallMs ~/ 2));
      final area = tester.getRect(arena);
      await tester.tapAt(
        area.topLeft +
            Offset(area.width * item.x, -50 + (area.height + 70) * 0.5),
      );
      await tester.pump();
    }

    testWidgets('las monedas suman y al final manda el puntaje', (
      tester,
    ) async {
      await show(tester, solo(MinigameType.coinRain));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      await catchItem(tester, coin);
      expect(find.text('+1'), findsOneWidget);
      await run(tester, 700);
      await tester.pump(_ms(_rules.coinRainMs));
      await tester.pump();
      expect(sent, [1]);
      expect(find.text('¡Cazaste 1 puntos!'), findsOneWidget);
    });

    testWidgets('las bombas restan, sin bajar de cero', (tester) async {
      final bomb = script.firstWhere((item) => item.kind == FallingKind.bomb);
      await show(tester, solo(MinigameType.coinRain));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      await catchItem(tester, bomb);
      expect(find.text('-3'), findsOneWidget);
      await run(tester, 700);
      await tester.pump(_ms(_rules.coinRainMs));
      await tester.pump();
      expect(sent, [0]);
    });

    testWidgets('tocar donde no hay nada no cuenta', (tester) async {
      await show(tester, solo(MinigameType.coinRain));
      await tester.pump(_ms(_rules.introMs + 10));
      await tester.pump();
      await tester.tapAt(
        tester.getRect(arena).bottomRight - const Offset(5, 5),
      );
      await tester.pump();
      expect(find.text('+1'), findsNothing);
      await tester.pump(_ms(_rules.coinRainMs));
      await tester.pump();
      expect(sent, [0]);
    });
  });

  group('Color Tramposo', () {
    const names = ['ROJO', 'AZUL', 'VERDE', 'AMARILLO', 'MORADO', 'NARANJA'];
    final rounds = colorTrapScript(
      _seed,
      rounds: _rules.colorTrapRounds,
      flipFrom: _rules.colorTrapFlipFrom,
      colors: _rules.colorTrapColors,
    );

    Future<void> press(WidgetTester tester, int color) async {
      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is MinigameButton && widget.label == names[color],
          ),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pump();
    }

    testWidgets('vale la tinta y no lo que dice la palabra', (tester) async {
      await show(tester, solo(MinigameType.colorTrap));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      expect(find.text('Vale la TINTA'), findsOneWidget);
      expect(find.text('1/15'), findsOneWidget);
      await press(tester, rounds[0].ink);
      expect(find.text('2/15'), findsOneWidget);
      expect(find.text('0'), findsNothing, reason: 'ya tiene puntos');
    });

    testWidgets('tocar lo que dice la palabra no da puntos', (tester) async {
      await show(tester, solo(MinigameType.colorTrap));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      await press(tester, rounds[0].word);
      expect(find.text('2/15'), findsOneWidget);
      expect(find.text('0'), findsOneWidget, reason: 'sigue en cero');
    });

    testWidgets('dejar pasar el tiempo cuenta como error', (tester) async {
      await show(tester, solo(MinigameType.colorTrap));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump(_ms(_rules.colorTrapWordMs));
      await tester.pump();
      expect(find.text('2/15'), findsOneWidget);
    });

    testWidgets('la regla se voltea y al final manda los puntos', (
      tester,
    ) async {
      await show(tester, solo(MinigameType.colorTrap));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      for (var i = 0; i < _rules.colorTrapFlipFrom; i++) {
        await press(tester, rounds[i].answer);
        await tester.pump(_ms(50));
      }
      expect(find.text('¡TRAMPA!'), findsOneWidget);
      await run(tester, 1400);
      expect(find.text('Vale la PALABRA'), findsOneWidget);
      for (var i = _rules.colorTrapFlipFrom; i < 15; i++) {
        expect(rounds[i].answer, rounds[i].word);
        await press(tester, rounds[i].answer);
        await tester.pump(_ms(50));
      }
      expect(sent, hasLength(1));
      expect(sent.single, greaterThan(15 * 100));
      expect(sent.single, lessThanOrEqualTo(_rules.colorTrapMaxScore));
    });

    testWidgets('los botones siempre coinciden con su color', (tester) async {
      await show(tester, solo(MinigameType.colorTrap));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await press(tester, rounds[i].answer);
        for (final button in tester.widgetList<MinigameButton>(
          find.byType(MinigameButton),
        )) {
          expect(button.color, AppColors.players[names.indexOf(button.label)]);
        }
      }
    });
  });

  group('Cuenta Rápida', () {
    final problems = quickMathScript(_seed, _rules.quickMathProblems);

    Future<void> answer(WidgetTester tester, MathProblem problem, bool right) {
      final left = right == problem.leftIsRight;
      return tester.tap(find.text('${left ? problem.left : problem.right}'));
    }

    testWidgets('las buenas suman y hacen racha', (tester) async {
      await show(tester, solo(MinigameType.quickMath));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      expect(find.text('${problems[0].text} = ?'), findsOneWidget);
      await answer(tester, problems[0], true);
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
      await answer(tester, problems[1], true);
      await tester.pump();
      expect(find.text('22'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('${problems[2].text} = ?'), findsOneWidget);
    });

    testWidgets('las malas restan y hacen esperar un momento', (tester) async {
      await show(tester, solo(MinigameType.quickMath));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      await answer(tester, problems[0], true);
      await tester.pump();
      await answer(tester, problems[1], false);
      await tester.pump();
      expect(find.text('5'), findsOneWidget, reason: '10 - 5');
      expect(find.text('x2'), findsNothing);

      // Un toque de inmediato no cuenta.
      await answer(tester, problems[2], true);
      await tester.pump();
      expect(find.text('${problems[2].text} = ?'), findsOneWidget);
      await tester.pump(_ms(500));
      await answer(tester, problems[2], true);
      await tester.pump();
      expect(find.text('${problems[3].text} = ?'), findsOneWidget);
    });

    testWidgets('al acabarse el tiempo manda los puntos', (tester) async {
      await show(tester, solo(MinigameType.quickMath));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      await answer(tester, problems[0], true);
      await tester.pump(_ms(_rules.quickMathMs));
      await tester.pump();
      expect(sent, [10]);
      expect(find.text('¡10 puntos!'), findsOneWidget);
    });
  });

  group('Cofre Fuerte', () {
    final locks = safeLockScript(_seed, _rules.safeLocks);

    /// Avanza hasta que la aguja queda en la marca y la detiene.
    Future<void> hit(WidgetTester tester, SafeLockSetup lock) async {
      var ms = 0;
      while (safeLockDistance(lock.needleAt(ms), lock.markDeg) > 2) {
        ms += 4;
      }
      await tester.pump(_ms(ms));
      await tester.tap(find.text('¡Alto!'));
      await tester.pump();
    }

    testWidgets('abrir los tres cerrojos da el cofre mejor', (tester) async {
      await show(tester, solo(MinigameType.safeLock));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      for (final lock in locks) {
        await hit(tester, lock);
        await tester.pump(_ms(420));
        expect(find.textContaining('¡Perfecto!'), findsOneWidget);
        await tester.pump(_ms(600));
        await tester.pump();
      }
      expect(find.text('¡Abriste 3 de 3!'), findsOneWidget);
      expect(sent, isEmpty, reason: 'primero se ve el cofre');
      await run(tester, 1600);
      expect(sent, hasLength(1));
      expect(sent.single, greaterThan(400));
    });

    testWidgets('fallar no da puntos', (tester) async {
      await show(tester, solo(MinigameType.safeLock));
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      await tester.tap(find.text('¡Alto!'));
      await tester.pump(_ms(420));
      await tester.pump(_ms(420));
      expect(find.text('¡Fallaste!'), findsOneWidget);
    });

    testWidgets('si no detiene la aguja, se detiene sola', (tester) async {
      await show(tester, solo(MinigameType.safeLock));
      await tester.pump(_ms(_rules.introMs));
      for (var lock = 0; lock < _rules.safeLocks; lock++) {
        await tester.pump(_ms(_rules.safeLockTurnMs));
        await tester.pump();
        await tester.pump(_ms(1100));
        await tester.pump();
      }
      expect(find.text('Sigue cerrado'), findsOneWidget);
      await run(tester, 1600);
      expect(sent, [0]);
    });
  });

  group('Cables Rojos', () {
    const bomb = MinigameState(
      type: MinigameType.wires,
      round: 1,
      players: ['ana', 'beto', 'caro'],
      wires: 5,
    );
    final wires = find.descendant(
      of: find.byType(MinigameView),
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onTapDown != null,
      ),
    );

    testWidgets('en tu turno cortas un cable, una sola vez', (tester) async {
      await show(tester, bomb);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      expect(find.textContaining('Tu turno'), findsOneWidget);
      expect(wires, findsNWidgets(5));

      await tester.tap(wires.at(2));
      await tester.pump();
      expect(sent, [2]);
      await tester.pump(_ms(100));
      expect(wires, findsNothing, reason: 'ya no se puede cortar');
    });

    testWidgets('en el turno de otro solo se mira', (tester) async {
      await show(tester, bomb.copyWith(turn: 1, step: 1));
      await tester.pump();
      expect(find.text('Turno de Beto'), findsOneWidget);
      expect(wires, findsNothing);
    });

    testWidgets('los cables cortados ya no se pueden tocar', (tester) async {
      await show(tester, bomb.copyWith(step: 3, cut: [0, 1]));
      await tester.pump();
      await tester.tap(wires.at(0));
      await tester.pump();
      expect(sent, isEmpty);
      await tester.tap(wires.at(4));
      await tester.pump();
      expect(sent, [4]);
    });

    testWidgets('si no cortas a tiempo, se corta uno por ti', (tester) async {
      await show(tester, bomb);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump(_ms(_rules.wiresTurnMs));
      await tester.pump();
      expect(sent, hasLength(1));
      expect(sent.single, inInclusiveRange(0, 4));
    });

    testWidgets('cuando explota lo avisa y no deja cortar', (tester) async {
      await show(tester, bomb.copyWith(step: 3, cut: [1]));
      await tester.pump();
      await tester.pumpWidget(
        app(
          bomb.copyWith(
            step: 4,
            stage: 1,
            wires: 4,
            cut: const [],
            out: ['beto'],
            cursed: 3,
          ),
          'ana',
        ),
      );
      await tester.pump(_ms(100));
      expect(find.text('¡BOOM!'), findsOneWidget);
      expect(find.text('¡Le explotó a Beto!'), findsOneWidget);
      expect(wires, findsNothing);

      await run(tester, _rules.wiresBoomMs);
      expect(find.text('¡BOOM!'), findsNothing);
      expect(find.textContaining('Tu turno'), findsOneWidget);
      expect(wires, findsNWidgets(4));
      await run(tester, 1000);
    });
  });

  group('Puja Secreta', () {
    const start = MinigameState(
      type: MinigameType.secretBid,
      round: 1,
      players: _ids,
      chips: {'ana': 15, 'beto': 15},
    );

    testWidgets('pujas una vez y la puja queda en secreto', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      expect(find.text('Puja 1 de 3'), findsOneWidget);
      expect(find.text('15 fichas'), findsOneWidget);

      await tester.tap(find.text('7'));
      await tester.pump();
      expect(sent, [MinigamePick.encode(0, 7)]);
      expect(find.text('¡Puja lista!'), findsOneWidget);
      expect(find.text('7'), findsNothing);
    });

    testWidgets('no se puede pujar más de lo que tienes', (tester) async {
      await show(
        tester,
        start.copyWith(stage: 1, chips: {'ana': 4, 'beto': 15}),
      );
      await tester.pump();
      await tester.tap(find.text('9'));
      await tester.pump();
      expect(sent, isEmpty);
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(sent, [MinigamePick.encode(1, 3)]);
    });

    testWidgets('puedes pasar y guardar tus fichas', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      await tester.tap(find.text('Pasar y guardar mis fichas'));
      await tester.pump();
      expect(sent, [MinigamePick.encode(0, 0)]);
    });

    testWidgets('si se acaba el tiempo, avisa que no pujó', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump(_ms(_rules.bidChoiceMs));
      await tester.pump();
      expect(sent, [MinigamePick.encode(0, MinigamePick.none)]);
    });

    testWidgets('al revelar, se ven las pujas y quién ganó', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pumpWidget(
        app(
          start.copyWith(
            step: 2,
            stage: 1,
            picks: {'ana': 6, 'beto': 4},
            points: {'ana': 1},
            chips: {'ana': 9, 'beto': 11},
          ),
          'ana',
        ),
      );
      await tester.pump();
      expect(find.text('Puja 1 de 3'), findsOneWidget);
      expect(find.text('?'), findsNWidgets(2), reason: 'boca abajo');
      expect(find.text('15'), findsNWidgets(2), reason: 'no se adelanta');

      await run(tester, 1400);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('¡Gana Ana!'), findsOneWidget);
      expect(find.text('9'), findsOneWidget, reason: 'ya se gastaron');

      await run(tester, _rules.bidRevealMs);
      expect(find.text('Puja 2 de 3'), findsOneWidget);
    });

    testWidgets('las repetidas se anulan', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pumpWidget(
        app(
          start.copyWith(
            step: 2,
            stage: 1,
            picks: {'ana': 6, 'beto': 6},
            chips: {'ana': 9, 'beto': 9},
          ),
          'ana',
        ),
      );
      await run(tester, 1400);
      expect(find.text('se anuló'), findsNWidgets(2));
      expect(find.text('¡Nadie gana esta puja!'), findsOneWidget);
      await run(tester, _rules.bidRevealMs);
    });
  });

  group('Mayor o Menor', () {
    const start = MinigameState(
      type: MinigameType.highLow,
      round: 1,
      players: ['ana', 'beto', 'caro'],
      card: 7,
    );

    testWidgets('apuestas una vez', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
      await tester.tap(find.text('Mayor'));
      await tester.pump();
      expect(sent, [MinigamePick.encode(0, 1)]);
      expect(find.text('Apostaste Mayor'), findsOneWidget);
      expect(find.text('Menor'), findsNothing);
    });

    testWidgets('si se acaba el tiempo, avisa que no apostó', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump(_ms(_rules.highLowChoiceMs));
      await tester.pump();
      expect(sent, [MinigamePick.encode(0, MinigamePick.none)]);
    });

    testWidgets('se voltea la carta y sale quien falló', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pumpWidget(
        app(
          start.copyWith(
            step: 3,
            stage: 1,
            card: 11,
            previousCard: 7,
            picks: {'ana': 1, 'beto': 0, 'caro': 1},
            out: ['beto'],
          ),
          'ana',
        ),
      );
      await tester.pump();
      expect(find.text('Veamos...'), findsOneWidget);

      await run(tester, 1400);
      expect(find.text('¡Mayor!'), findsOneWidget);
      expect(find.text('Fuera: Beto'), findsOneWidget);

      await run(tester, _rules.highLowRevealMs);
      expect(find.text('¡Mayor!'), findsNothing);
      expect(find.text('Mayor'), findsOneWidget, reason: 'siguiente carta');
    });

    testWidgets('quien quedó fuera solo mira', (tester) async {
      await show(tester, start.copyWith(stage: 1, out: ['ana']));
      await run(tester, _rules.highLowRevealMs + 300);
      expect(find.text('Estás fuera: mira cómo acaban'), findsOneWidget);
      expect(find.text('Mayor'), findsNothing);
    });

    testWidgets('si no sale nadie, también lo dice', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pumpWidget(
        app(
          start.copyWith(
            step: 3,
            stage: 1,
            card: 2,
            previousCard: 7,
            picks: {'ana': 1, 'beto': 1, 'caro': 1},
          ),
          'ana',
        ),
      );
      await run(tester, 1400);
      expect(find.text('¡Menor!'), findsOneWidget);
      expect(find.text('Nadie sale'), findsOneWidget);
      await run(tester, _rules.highLowRevealMs);
    });
  });

  group('La Silla Fantasma', () {
    const start = MinigameState(
      type: MinigameType.ghostChair,
      round: 1,
      players: _ids,
      points: {'ana': 2, 'beto': 2},
    );
    final chairs = find.byWidgetPredicate(
      (widget) => widget is GestureDetector && widget.onTapDown != null,
    );

    testWidgets('eliges una silla una sola vez', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump();
      expect(find.text('¿En qué silla te sientas?'), findsOneWidget);
      expect(chairs, findsNWidgets(_rules.chairs));
      await tester.tap(chairs.at(1));
      await tester.pump();
      expect(sent, [MinigamePick.encode(0, 1)]);
      expect(find.text('Esperando a los demás...'), findsOneWidget);
      expect(chairs, findsNothing);
    });

    testWidgets('si se acaba el tiempo, avisa que no eligió', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pump(_ms(_rules.chairChoiceMs));
      await tester.pump();
      expect(sent, [MinigamePick.encode(0, MinigamePick.none)]);
    });

    testWidgets('la vida se pierde cuando llega el fantasma', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pumpWidget(
        app(
          start.copyWith(
            step: 3,
            stage: 1,
            picks: {'ana': 1, 'beto': 0},
            cursed: 1,
            points: {'ana': 1, 'beto': 2},
          ),
          'ana',
        ),
      );
      await tester.pump();
      expect(find.text('Ya viene el fantasma...'), findsOneWidget);
      int fullHearts() => tester
          .widgetList<Icon>(find.byIcon(Icons.favorite_rounded))
          .where((icon) => icon.color == AppColors.minigameOut)
          .length;
      expect(fullHearts(), 4, reason: 'todavía no llega');

      await run(tester, 2900);
      expect(find.text('Atrapó a Ana'), findsOneWidget);
      expect(fullHearts(), 3);

      await run(tester, 1300);
      expect(find.text('¿En qué silla te sientas?'), findsOneWidget);
    });

    testWidgets('si llega a una silla vacía, nadie pierde', (tester) async {
      await show(tester, start);
      await tester.pump(_ms(_rules.introMs));
      await tester.pumpWidget(
        app(
          start.copyWith(
            step: 3,
            stage: 1,
            picks: {'ana': 1, 'beto': 1},
            cursed: 2,
          ),
          'ana',
        ),
      );
      await run(tester, 2900);
      expect(find.text('¡Silla vacía! Nadie pierde'), findsOneWidget);
      await run(tester, 1300);
    });
  });

  group('El resultado', () {
    Future<void> showResult(WidgetTester tester, MinigameResult result) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MinigameResultCard(
                result: result,
                players: _players,
                coins: 10,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('dice lo que hizo cada uno en su medida', (tester) async {
      const cases = {
        MinigameType.rhythm: '38 ms de desvío',
        MinigameType.diceMemory: '38 dados',
        MinigameType.coinRain: '38 puntos',
        MinigameType.colorTrap: '38 puntos',
        MinigameType.quickMath: '38 puntos',
        MinigameType.safeLock: '38 puntos',
      };
      for (final MapEntry(key: type, value: text) in cases.entries) {
        await showResult(
          tester,
          MinigameResult(
            type: type,
            round: 1,
            winnerIds: const ['ana'],
            scores: const {'ana': 38},
          ),
        );
        expect(find.textContaining(text, findRichText: true), findsOneWidget);
      }
    });

    testWidgets('en Puja Secreta dice vueltas y fichas', (tester) async {
      await showResult(
        tester,
        const MinigameResult(
          type: MinigameType.secretBid,
          round: 1,
          winnerIds: ['ana'],
          scores: {'ana': 204, 'beto': 100},
        ),
      );
      expect(
        find.textContaining('2 pujas ganadas y 4 fichas', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('1 puja ganada y 0 fichas', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('en los de eliminación dice cómo salió cada uno', (
      tester,
    ) async {
      const cases = {
        MinigameType.wires: 'hizo explotar la bomba',
        MinigameType.highLow: 'falló la carta',
        MinigameType.ghostChair: 'se quedó sin vidas',
      };
      for (final MapEntry(key: type, value: text) in cases.entries) {
        await showResult(
          tester,
          MinigameResult(
            type: type,
            round: 1,
            winnerIds: const ['ana'],
            out: const ['beto'],
          ),
        );
        expect(find.textContaining(text, findRichText: true), findsOneWidget);
      }
    });
  });

  // `tester.tap` baja y sube el dedo sin que pase ningún cuadro. Un dedo real
  // se queda encima unos milisegundos, y mientras tanto la pantalla cambia.
  group('Con el dedo de verdad', () {
    const held = 12;

    /// Baja el dedo en [at], deja pasar unos cuadros y lo sube.
    Future<void> press(WidgetTester tester, Offset at) async {
      final finger = await tester.startGesture(at);
      for (var frame = 0; frame < held; frame++) {
        await tester.pump(_ms(16));
      }
      await finger.up();
      await tester.pump(_ms(16));
    }

    Future<void> pressOn(WidgetTester tester, Finder target) =>
        press(tester, tester.getCenter(target));

    testWidgets('un botón se puede desactivar con el dedo encima', (
      tester,
    ) async {
      var taps = 0;
      VoidCallback? onPressed = () => taps++;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return MinigameButton(label: 'Dale', onPressed: onPressed);
                },
              ),
            ),
          ),
        ),
      );

      final finger = await tester.startGesture(
        tester.getCenter(find.text('Dale')),
      );
      await tester.pump(_ms(200));
      update(() => onPressed = null);
      await tester.pump(_ms(200));
      expect(tester.takeException(), isNull);
      await finger.up();
      await tester.pump(_ms(200));
      expect(tester.takeException(), isNull);
      expect(taps, 0, reason: 'al soltarlo ya estaba desactivado');

      // Al volver a activarlo funciona normal.
      update(() => onPressed = () => taps++);
      await tester.pump(_ms(200));
      await pressOn(tester, find.text('Dale'));
      expect(taps, 1);
    });

    testWidgets('Cofre Fuerte se juega completo con el botón', (tester) async {
      await show(tester, solo(MinigameType.safeLock));
      await run(tester, _rules.introMs + 800, step: 16);
      for (var lock = 0; lock < _rules.safeLocks; lock++) {
        await pressOn(tester, find.text('¡Alto!'));
        await run(tester, 1300, step: 16);
      }
      await run(tester, 1700, step: 16);
      expect(sent, hasLength(1));
    });

    testWidgets('Cofre Fuerte se juega completo tocando la cerradura', (
      tester,
    ) async {
      await show(tester, solo(MinigameType.safeLock));
      await run(tester, _rules.introMs + 800, step: 16);
      for (var lock = 0; lock < _rules.safeLocks; lock++) {
        await pressOn(tester, find.byType(CustomPaint).first);
        await run(tester, 1300, step: 16);
      }
      await run(tester, 1700, step: 16);
      expect(sent, hasLength(1));
    });

    testWidgets('Color Tramposo aguanta el dedo mientras cambia la palabra', (
      tester,
    ) async {
      await show(tester, solo(MinigameType.colorTrap));
      await run(tester, _rules.introMs + 100, step: 16);
      final finger = await tester.startGesture(
        tester.getCenter(find.byType(MinigameButton).first),
      );
      // Se acaba el tiempo de la palabra con el dedo todavía encima.
      await run(tester, _rules.colorTrapWordMs + 100, step: 16);
      expect(find.text('2/15'), findsOneWidget);
      await finger.up();
      await tester.pump(_ms(16));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Cuenta Rápida aguanta dos dedos a la vez', (tester) async {
      await show(tester, solo(MinigameType.quickMath));
      await run(tester, _rules.introMs + 100, step: 16);
      final problems = quickMathScript(_seed, _rules.quickMathProblems);
      final first = problems.first;
      final right = first.leftIsRight ? first.left : first.right;
      final wrong = first.leftIsRight ? first.right : first.left;
      // Un dedo espera sobre la respuesta buena y el otro toca la mala: los
      // botones se desactivan con el primer dedo todavía encima.
      final waiting = await tester.startGesture(
        tester.getCenter(find.text('$right')),
        pointer: 7,
      );
      await tester.pump(_ms(150));
      await pressOn(tester, find.text('$wrong'));
      await run(tester, 200, step: 16);
      await waiting.up();
      await run(tester, 600, step: 16);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Memoria de Dados aguanta soltar un dado que ya no está', (
      tester,
    ) async {
      final faces = diceMemoryFaces(_seed, _rules.diceMemoryMax);
      await show(tester, solo(MinigameType.diceMemory));
      await tester.pump(_ms(_rules.introMs));
      await run(tester, 3 * 640 + 300, step: 50);
      Finder die(int face) => find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            (widget.width ?? 0) > 40 &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == MapAssets.dice(face),
      );
      await pressOn(tester, die(faces[0]));
      await pressOn(tester, die(faces[1]));
      final finger = await tester.startGesture(tester.getCenter(die(faces[2])));
      // Sigue con el dedo encima hasta que los botones desaparecen.
      await run(tester, 900, step: 16);
      expect(find.text('¡Memoriza!'), findsOneWidget);
      await finger.up();
      await tester.pump(_ms(16));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Cazamonedas y Pulso Perfecto reciben el dedo sin romperse', (
      tester,
    ) async {
      for (final type in [MinigameType.coinRain, MinigameType.rhythm]) {
        await show(tester, solo(type));
        await run(tester, _rules.introMs + 3000, step: 16);
        await pressOn(tester, find.byType(MinigameArena));
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('Para el Tiempo y Globo Bomba mandan una sola vez', (
      tester,
    ) async {
      await show(
        tester,
        const MinigameState(
          type: MinigameType.stopwatch,
          round: 1,
          players: _ids,
          targetMs: 5000,
        ),
      );
      await run(tester, _rules.introMs + 500, step: 16);
      await pressOn(tester, find.text('¡Ya!'));
      expect(sent, hasLength(1));
      await tester.pumpWidget(const SizedBox());

      sent.clear();
      await show(
        tester,
        const MinigameState(
          type: MinigameType.balloon,
          round: 1,
          players: _ids,
          capacity: 40,
        ),
      );
      await run(tester, _rules.introMs + 100, step: 16);
      await pressOn(tester, find.text('+2'));
      expect(sent, [2]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Cables Rojos corta con el dedo encima', (tester) async {
      await show(
        tester,
        const MinigameState(
          type: MinigameType.wires,
          round: 1,
          players: ['ana', 'beto', 'caro'],
          wires: 5,
        ),
      );
      await run(tester, _rules.introMs + 100, step: 16);
      await pressOn(tester, find.byIcon(Icons.content_cut_rounded).at(2));
      expect(sent, hasLength(1));
      await run(tester, 300, step: 16);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Puja, Mayor o Menor y la Silla eligen con el dedo encima', (
      tester,
    ) async {
      await show(
        tester,
        const MinigameState(
          type: MinigameType.secretBid,
          round: 1,
          players: _ids,
          chips: {'ana': 15, 'beto': 15},
        ),
      );
      await run(tester, _rules.introMs + 100, step: 16);
      await pressOn(tester, find.text('7'));
      expect(sent, [MinigamePick.encode(0, 7)]);
      await tester.pumpWidget(const SizedBox());

      sent.clear();
      await show(
        tester,
        const MinigameState(
          type: MinigameType.highLow,
          round: 1,
          players: _ids,
          card: 7,
        ),
      );
      await run(tester, _rules.introMs + 100, step: 16);
      await pressOn(tester, find.text('Mayor'));
      expect(sent, [MinigamePick.encode(0, 1)]);
      await tester.pumpWidget(const SizedBox());

      sent.clear();
      await show(
        tester,
        const MinigameState(
          type: MinigameType.ghostChair,
          round: 1,
          players: _ids,
          points: {'ana': 2, 'beto': 2},
        ),
      );
      await run(tester, _rules.introMs + 100, step: 16);
      await pressOn(
        tester,
        find
            .byWidgetPredicate(
              (widget) => widget is GestureDetector && widget.onTapDown != null,
            )
            .first,
      );
      expect(sent, [MinigamePick.encode(0, 0)]);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('El texto con contorno', () {
    Future<void> showText(WidgetTester tester, double scale) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      return tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: MinigameOutlinedText('ROJO', fontSize: 40)),
          ),
        ),
      );
    }

    testWidgets('es un solo texto con cualquier tamaño de letra', (
      tester,
    ) async {
      // Con dos capas, el contorno y las letras podían quedar de tamaños
      // distintos en un teléfono con la letra pequeña.
      for (final scale in const [0.85, 1.0, 1.3]) {
        await showText(tester, scale);
        expect(find.text('ROJO'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(MinigameOutlinedText),
            matching: find.byType(RichText),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('el contorno rodea las letras a la misma distancia', (
      tester,
    ) async {
      await showText(tester, 1);
      final text = tester.widget<Text>(find.text('ROJO'));
      final shadows = text.style!.shadows!;
      expect(shadows.length, greaterThan(7));
      for (final shadow in shadows) {
        expect(shadow.blurRadius, 0);
        expect(shadow.offset.distance, closeTo(2, 0.001));
      }
    });

    testWidgets('los botones de color claro llevan contorno', (tester) async {
      Text labelOf(String label) => tester.widget<Text>(find.text(label));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MinigameButton(
                  label: 'CLARO',
                  color: AppColors.players[3],
                  onPressed: () {},
                ),
                MinigameButton(
                  label: 'OSCURO',
                  color: AppColors.players[1],
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(labelOf('CLARO').style!.shadows!.length, greaterThan(1));
      expect(labelOf('OSCURO').style!.shadows, hasLength(1));
    });
  });

  test('cada minijuego tiene su color y su ícono', () {
    final accents = {for (final type in MinigameType.values) type.accent};
    final icons = {for (final type in MinigameType.values) type.icon};
    expect(icons, hasLength(MinigameType.values.length));
    expect(accents.length, greaterThan(MinigameType.values.length - 3));
  });
}
