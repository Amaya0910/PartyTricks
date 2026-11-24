import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/widgets/dice_roll_overlay.dart';

/// La tirada del dado: uno solo, o dos si el jugador usó un dado extra.
void main() {
  Future<void> throwDice(WidgetTester tester, DiceRoll roll) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: DiceRollOverlay(roll: null)),
    );
    await tester.pumpWidget(MaterialApp(home: DiceRollOverlay(roll: roll)));
    await tester.pump();
  }

  const mainDie = Key('die-main');
  const extraDie = Key('die-extra');

  /// Las imágenes (o números) que muestra un dado.
  Set<String> shown(WidgetTester tester, Key die) => {
    for (final image in tester.widgetList<Image>(
      find.descendant(of: find.byKey(die), matching: find.byType(Image)),
    ))
      if (image.image case final AssetImage asset) asset.assetName,
  };

  DiceRoll roll({int value = 4, int extra = 0, int boost = 0}) => DiceRoll(
    serial: 1,
    username: 'Ana',
    color: Colors.blue,
    value: value,
    extra: extra,
    boost: boost,
  );

  testWidgets('sin dado extra se lanza un solo dado', (tester) async {
    await throwDice(tester, roll());
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.byKey(mainDie), findsOneWidget);
    expect(find.byKey(extraDie), findsNothing);
    expect(find.text('Ana sacó 4'), findsOneWidget);
  });

  testWidgets('con dado extra se lanzan dos dados, cada uno con su número', (
    tester,
  ) async {
    await throwDice(tester, roll(value: 4, extra: 5));
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.byKey(mainDie), findsOneWidget);
    expect(find.byKey(extraDie), findsOneWidget);
    expect(shown(tester, mainDie), {'assets/images/juego/dado_4.png'});
    expect(shown(tester, extraDie), {'assets/images/juego/dado_5.png'});
    // Juntos, uno al lado del otro y a la misma altura una vez que cayeron.
    final main = tester.getCenter(find.byKey(mainDie));
    final extra = tester.getCenter(find.byKey(extraDie));
    expect(extra.dx, greaterThan(main.dx));
    expect(extra.dy, closeTo(main.dy, 0.5));
    expect(find.text('Ana sacó 4 y 5'), findsOneWidget);
    expect(find.text('+5 dado extra = avanza 9'), findsOneWidget);
  });

  testWidgets('los dos dados caen: al principio están más arriba y el extra '
      'sale un instante después', (tester) async {
    await throwDice(tester, roll(value: 3, extra: 2));
    await tester.pump(const Duration(milliseconds: 1500));
    final mainEnd = tester.getCenter(find.byKey(mainDie)).dy;
    final extraEnd = tester.getCenter(find.byKey(extraDie)).dy;

    await throwDice(tester, roll(value: 3, extra: 2).copyWithSerial(2));
    await tester.pump(const Duration(milliseconds: 100));

    final mainStart = tester.getCenter(find.byKey(mainDie)).dy;
    final extraStart = tester.getCenter(find.byKey(extraDie)).dy;
    expect(mainStart, lessThan(mainEnd));
    expect(extraStart, lessThan(extraEnd));
    // El extra todavía está más arriba que el normal: salió después.
    expect(extraStart, lessThan(mainStart));
  });

  testWidgets('un dado extra de 9 caras se ve con su número aunque no haya '
      'dibujo para él', (tester) async {
    await throwDice(tester, roll(value: 2, extra: 8));
    await tester.pump(const Duration(milliseconds: 1500));
    // Deja que termine de fallar la carga de la imagen que no existe.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(
      find.descendant(of: find.byKey(extraDie), matching: find.text('8')),
      findsOneWidget,
    );
    expect(find.text('+8 dado extra = avanza 10'), findsOneWidget);
  });

  testWidgets('avisa cuando el dado empieza a animarse y cuando termina', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final reports = <bool>[];
    Widget overlay(DiceRoll? roll) => MaterialApp(
      home: DiceRollOverlay(roll: roll, onBusyChanged: reports.add),
    );

    await tester.pumpWidget(overlay(null));
    await tester.pumpWidget(overlay(roll(extra: 3)));
    await tester.pump();
    expect(reports, [true]);

    // Todavía cayendo y mostrando el resultado.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(reports, [true]);

    // Terminó (2,4 s en total).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(reports, [true, false]);
  });
}

extension on DiceRoll {
  /// La misma tirada, pero otra: así vuelve a animarse.
  DiceRoll copyWithSerial(int serial) => DiceRoll(
    serial: serial,
    username: username,
    color: color,
    value: value,
    extra: extra,
    boost: boost,
  );
}
