import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/widgets/auth_text_field.dart';

void main() {
  Widget host({required bool isPassword}) {
    return MaterialApp(
      home: Scaffold(
        body: AuthTextField(
          controller: TextEditingController(),
          hint: 'Contraseña',
          isPassword: isPassword,
        ),
      ),
    );
  }

  bool isObscured(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).obscureText;

  testWidgets('un campo normal no oculta el texto ni muestra el ojo',
      (tester) async {
    await tester.pumpWidget(host(isPassword: false));

    expect(isObscured(tester), isFalse);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
  });

  testWidgets('la contraseña empieza oculta con el ojo a un lado',
      (tester) async {
    await tester.pumpWidget(host(isPassword: true));

    expect(isObscured(tester), isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('tocar el ojo muestra y vuelve a ocultar la contraseña',
      (tester) async {
    await tester.pumpWidget(host(isPassword: true));

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(isObscured(tester), isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(isObscured(tester), isTrue);
  });
}
