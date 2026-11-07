import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';

void main() {
  group('la foto guardada', () {
    String textOf(int seed) => base64Encode(Uint8List.fromList([seed, 1, 2]));

    test('leerla otra vez no la decodifica de nuevo', () {
      final text = textOf(200);
      final first = FacePhoto.fromStored(text)!;
      // Cada lectura de Firestore trae un texto nuevo con el mismo contenido.
      final again = FacePhoto.fromStored(String.fromCharCodes(text.codeUnits))!;

      expect(identical(first, again), isTrue);
    });

    test('recuerda solo las últimas fotos', () {
      final first = FacePhoto.fromStored(textOf(0))!;
      for (var seed = 1; seed < 40; seed++) {
        FacePhoto.fromStored(textOf(seed));
      }

      final again = FacePhoto.fromStored(textOf(0))!;
      expect(identical(first, again), isFalse);
      expect(again, first);
    });
  });

  group('el personaje animado', () {
    testWidgets('solo mueve sus capas: no las vuelve a armar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            height: 300,
            child: AnimatedCharacter(skinTone: Colors.teal),
          ),
        ),
      );
      List<CharacterLayer> layers() => tester
          .widgetList<CharacterLayer>(find.byType(CharacterLayer))
          .toList();
      final before = layers();
      Matrix4 head() =>
          tester.widgetList<Transform>(find.byType(Transform)).last.transform;
      final headBefore = head().clone();

      await tester.pump(const Duration(milliseconds: 600));

      final after = layers();
      expect(after, hasLength(before.length));
      for (var i = 0; i < before.length; i++) {
        expect(identical(before[i], after[i]), isTrue);
      }
      expect(head(), isNot(headBefore));
    });

    testWidgets('tiñe el relleno sin abrir una capa aparte', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            height: 300,
            child: AnimatedCharacter(skinTone: Colors.teal),
          ),
        ),
      );

      final image = tester
          .widgetList<Image>(find.byType(Image))
          .firstWhere((image) => image.color == Colors.teal);
      expect(image.colorBlendMode, BlendMode.modulate);
      expect(find.byType(ColorFiltered), findsNothing);
    });
  });
}
