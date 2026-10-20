import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/widgets/flip_card.dart';

void main() {
  Widget host({required bool showBack}) {
    return MaterialApp(
      home: SizedBox(
        width: 300,
        height: 300,
        child: FlipCard(
          showBack: showBack,
          front: const Text('frente'),
          back: const Text('atras'),
        ),
      ),
    );
  }

  testWidgets('muestra el frente cuando showBack es false', (tester) async {
    await tester.pumpWidget(host(showBack: false));

    expect(find.text('frente'), findsOneWidget);
    expect(find.text('atras'), findsNothing);
  });

  testWidgets('muestra la cara de atrás cuando showBack es true',
      (tester) async {
    await tester.pumpWidget(host(showBack: true));

    expect(find.text('atras'), findsOneWidget);
    expect(find.text('frente'), findsNothing);
  });

  testWidgets('da la vuelta al cambiar showBack', (tester) async {
    await tester.pumpWidget(host(showBack: false));

    await tester.pumpWidget(host(showBack: true));
    await tester.pumpAndSettle();
    expect(find.text('atras'), findsOneWidget);
    expect(find.text('frente'), findsNothing);

    await tester.pumpWidget(host(showBack: false));
    await tester.pumpAndSettle();
    expect(find.text('frente'), findsOneWidget);
    expect(find.text('atras'), findsNothing);
  });
}
