import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/widgets/no_players_left_view.dart';

void main() {
  testWidgets('muestra el mensaje de la fiesta y el botón para salir', (
    tester,
  ) async {
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(home: NoPlayersLeftView(onExit: () => exits++)),
    );

    expect(find.text('¡Se acabó la fiesta!'), findsOneWidget);
    expect(find.textContaining('no quedan jugadores'), findsOneWidget);
    expect(find.textContaining('party'), findsOneWidget);
    expect(find.textContaining('ya no da premios'), findsOneWidget);

    await tester.tap(find.text('Regresar a menú'));
    expect(exits, 1);
  });

  testWidgets('el botón atrás del celular también lleva al menú', (
    tester,
  ) async {
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(home: NoPlayersLeftView(onExit: () => exits++)),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 1);
  });
}
