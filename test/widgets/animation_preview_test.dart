import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/character_look_controller.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/screens/admin/animation_preview_screen.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_clips.dart';
import 'package:party_tricks/models/character_look.dart';

/// El personaje del administrador en las pruebas: camisa roja y orejas de ogro.
final _mine = CharacterLook(
  skinTone: Colors.brown,
  eyeColor: Colors.white,
  shirt: ShirtStyle.red,
  accessory: AccessoryStyle.ogre,
);

Widget _screen() => ProviderScope(
  overrides: [characterLookProvider.overrideWithValue(_mine)],
  child: const MaterialApp(home: AnimationPreviewScreen()),
);

void main() {
  group('la vista previa de animaciones', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_screen());
    }

    testWidgets('lista todas las animaciones y se puede ver cada una', (
      tester,
    ) async {
      await open(tester);

      for (final clip in CharacterClip.values) {
        expect(find.widgetWithText(ChoiceChip, clip.title), findsOneWidget);
      }
      for (final clip in CharacterClip.values) {
        await tester.tap(find.widgetWithText(ChoiceChip, clip.title));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(clip.description), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('cabe en un celular angosto', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_screen());
      await tester.tap(find.widgetWithText(ChoiceChip, 'Caminar'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    List<CharacterLayer> layers(WidgetTester tester) =>
        tester.widgetList<CharacterLayer>(find.byType(CharacterLayer)).toList();

    testWidgets('se ve con mi personaje: mi camisa y mi accesorio', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Caminar'));
      await tester.pump(const Duration(milliseconds: 300));

      final shirt = layers(
        tester,
      ).where((l) => l.asset.endsWith('lado/camisas/camisa_1.png'));
      expect(shirt, isNotEmpty);
      expect(shirt.every((l) => l.tint == ShirtStyle.red.tint), isTrue);
      expect(
        layers(
          tester,
        ).any((l) => l.asset.endsWith('accesorios/shrek_lado.png')),
        isTrue,
      );

      // Apagando el interruptor se ve el aspecto de inicio: sin accesorio.
      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        layers(tester).any((l) => l.asset.contains('accesorios/')),
        isFalse,
      );
      final blue = layers(
        tester,
      ).where((l) => l.asset.endsWith('lado/camisas/camisa_1.png'));
      expect(blue.every((l) => l.tint == ShirtStyle.blue.tint), isTrue);
    });

    testWidgets('arrastrar la fase la pausa', (tester) async {
      await open(tester);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('mirar a la izquierda solo aparece en las de lado', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Mirar a la izquierda'), findsNothing); // Reposo.

      await tester.tap(find.widgetWithText(ChoiceChip, 'Caminar'));
      await tester.pump();
      expect(find.text('Mirar a la izquierda'), findsOneWidget);
    });
  });

  testWidgets('el reposo sigue la fase que le dan, sin moverse solo', (
    tester,
  ) async {
    final phase = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
    );
    addTearDown(phase.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 300,
          child: CharacterClip.idle.build(
            look: CharacterLook.standard,
            phase: phase,
          ),
        ),
      ),
    );
    List<Matrix4> transforms() => tester
        .widgetList<Transform>(find.byType(Transform))
        .map((t) => t.transform.clone())
        .toList();

    final at0 = transforms();
    // El tiempo pasa pero la fase no: no cambia nada.
    await tester.pump(const Duration(seconds: 1));
    expect(transforms(), at0);

    phase.value = 0.5;
    await tester.pump();
    expect(transforms(), isNot(at0));
    expect(find.byType(AnimatedCharacter), findsOneWidget);
  });
}
