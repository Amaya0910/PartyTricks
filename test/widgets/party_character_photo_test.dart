import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/widgets/party_character.dart';

/// H-03: la foto de un jugador en la sala (photoUrl) la escribe ese mismo
/// jugador. Si la app descargara cualquier URL, ese jugador podría registrar
/// la IP de los demás o hacerlos pedir algo sin cifrar.
void main() {
  Future<void> pump(WidgetTester tester, String photoUrl) {
    return tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PartyCharacter(
            color: Colors.blue,
            height: 120,
            photoUrl: photoUrl,
          ),
        ),
      ),
    );
  }

  testWidgets('no descarga una foto de un servidor externo', (tester) async {
    await pump(tester, 'https://atacante.example/rastreo.png?sala=1');

    expect(find.byType(Image), findsNothing);
  });

  testWidgets('no descarga una foto por http (sin cifrar)', (tester) async {
    await pump(tester, 'http://lh3.googleusercontent.com/a/foto');

    expect(find.byType(Image), findsNothing);
  });

  testWidgets('muestra la foto de una cuenta de Google por HTTPS', (
    tester,
  ) async {
    await pump(tester, 'https://lh3.googleusercontent.com/a/ACg8ocJ-foto=s96-c');

    expect(find.byType(Image), findsOneWidget);
  });
}
