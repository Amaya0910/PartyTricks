import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/play_option.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/play_menu_dialog.dart';

void main() {
  Future<PlayOption?> open(WidgetTester tester) async {
    PlayOption? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async =>
                    chosen = await PlayMenuDialog.show(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return chosen;
  }

  testWidgets('usa la tarjeta de los demás diálogos con su título', (
    tester,
  ) async {
    await open(tester);

    expect(find.byType(DialogCard), findsOneWidget);
    expect(find.text('¡A la party!'), findsOneWidget);
    expect(find.text('Crear Party'), findsOneWidget);
    expect(find.text('Unirse a Party'), findsOneWidget);
    expect(find.text('Juego Random'), findsOneWidget);
  });

  testWidgets('cada botón devuelve su opción', (tester) async {
    for (final (label, option) in [
      ('Crear Party', PlayOption.createParty),
      ('Unirse a Party', PlayOption.joinParty),
      ('Juego Random', PlayOption.randomGame),
    ]) {
      PlayOption? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    chosen = await PlayMenuDialog.show(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(chosen, option, reason: label);
    }
  });
}
