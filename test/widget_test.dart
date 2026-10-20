import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/main.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';

/// Un jugador con la sesión ya iniciada.
const _jugador = UserProfile(
  uid: 'uid-prueba',
  email: 'tay@correo.com',
  username: 'Tay_pro32',
  friendCode: 'ABC234',
);

/// La app con el perfil [perfil] ya cargado (null = sin sesión), sin tocar
/// Firebase.
Widget _app({UserProfile? perfil = _jugador}) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Stream.value(perfil)),
    ],
    child: const PartyTricksApp(),
  );
}

/// Avanza el reloj de la prueba hasta que termina la pantalla de carga.
Future<void> _esperarCarga(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empieza en la pantalla de carga y luego pasa al inicio',
      (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Jugar'), findsNothing);

    await _esperarCarga(tester);

    expect(find.text('Jugar'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('sin sesión, después de la carga se ve el inicio de sesión',
      (tester) async {
    await tester.pumpWidget(_app(perfil: null));

    await _esperarCarga(tester);

    expect(find.text('Inicio de sesion'), findsOneWidget);
    expect(find.text('Jugar'), findsNothing);
  });

  testWidgets('la barra de navegación cambia de sección', (tester) async {
    await tester.pumpWidget(_app());
    await _esperarCarga(tester);

    expect(find.text('Jugar'), findsOneWidget);

    await tester.tap(find.text('Tienda'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de tienda'), findsOneWidget);
    expect(find.text('Jugar'), findsNothing);
  });

  testWidgets('el botón Jugar abre el menú de opciones', (tester) async {
    await tester.pumpWidget(_app());
    await _esperarCarga(tester);

    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Party'), findsOneWidget);
    expect(find.text('Unirse a Party'), findsOneWidget);
    expect(find.text('Juego Random'), findsOneWidget);
  });
}