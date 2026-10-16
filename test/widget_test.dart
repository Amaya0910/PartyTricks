import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/main.dart';

void main() {
  testWidgets('la barra de navegación cambia de sección', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PartyTricksApp()));

    // Empieza en Inicio.
    expect(find.text('Pantalla de inicio'), findsOneWidget);

    await tester.tap(find.text('Tienda'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de tienda'), findsOneWidget);
    expect(find.text('Pantalla de inicio'), findsNothing);
  });
}