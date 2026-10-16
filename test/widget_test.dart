import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/main.dart';

/// Avanza el reloj de la prueba hasta que termina la pantalla de carga.
Future<void> _esperarCarga(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empieza en la pantalla de carga y luego pasa al inicio',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PartyTricksApp()));

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Jugar'), findsNothing);

    await _esperarCarga(tester);

    expect(find.text('Jugar'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('la barra de navegación cambia de sección', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PartyTricksApp()));
    await _esperarCarga(tester);

    expect(find.text('Jugar'), findsOneWidget);

    await tester.tap(find.text('Tienda'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de tienda'), findsOneWidget);
    expect(find.text('Jugar'), findsNothing);
  });

  testWidgets('el botón Jugar abre el menú de opciones', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PartyTricksApp()));
    await _esperarCarga(tester);

    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Party'), findsOneWidget);
    expect(find.text('Unirse a Party'), findsOneWidget);
    expect(find.text('Juego Random'), findsOneWidget);
  });
}