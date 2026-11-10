import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/character/walking_character.dart';

void main() {
  group('el ciclo de caminata', () {
    const cycle = WalkCycle();

    test('empieza y termina en la misma pose, para repetirse sin saltos', () {
      final start = cycle.poseAt(0);
      final end = cycle.poseAt(1);
      expect(end.nearThigh, closeTo(start.nearThigh, 1e-9));
      expect(end.farThigh, closeTo(start.farThigh, 1e-9));
      expect(end.nearArm, closeTo(start.nearArm, 1e-9));
      expect(end.farKnee, closeTo(start.farKnee, 1e-9));
      expect(end.bodyDy, closeTo(start.bodyDy, 1e-9));
    });

    test('las dos piernas van en sentidos contrarios', () {
      for (var i = 0; i <= 20; i++) {
        final pose = cycle.poseAt(i / 20);
        expect(pose.nearThigh, closeTo(-pose.farThigh, 1e-9));
      }
    });

    test('cada brazo va al revés de la pierna de su lado', () {
      for (var i = 1; i < 20; i++) {
        final t = i / 20;
        if ((t - 0.5).abs() < 1e-9) continue;
        final pose = cycle.poseAt(t);
        expect(pose.nearArm.sign, -pose.nearThigh.sign);
        expect(pose.farArm.sign, -pose.farThigh.sign);
      }
    });

    test('la rodilla solo se dobla hacia atrás y la pierna abre su paso', () {
      var widest = 0.0;
      for (var i = 0; i <= 100; i++) {
        final pose = cycle.poseAt(i / 100);
        expect(pose.nearKnee, inInclusiveRange(0, cycle.kneeBend));
        expect(pose.farKnee, inInclusiveRange(0, cycle.kneeBend));
        expect(pose.bodyDy, greaterThanOrEqualTo(0));
        widest = math.max(widest, pose.nearThigh.abs());
      }
      expect(widest, closeTo(cycle.stride, 0.01));
    });

    test('una pierna levanta el pie mientras la otra está apoyada', () {
      // A un cuarto del ciclo la cercana está al frente (extendida) y la
      // lejana atrás, sin doblar.
      final pose = cycle.poseAt(0.25);
      expect(pose.nearKnee, closeTo(0, 1e-9));
      expect(pose.farKnee, closeTo(0, 1e-9));
      // Pasando por el centro, la que avanza va doblada.
      final passing = cycle.poseAt(0);
      expect(passing.nearKnee, greaterThan(0));
      expect(passing.farKnee, 0);
    });
  });

  group('el personaje caminando', () {
    Widget app(Animation<double> phase, {bool faceRight = true}) => MaterialApp(
      home: SizedBox(
        height: 300,
        child: WalkingCharacter(
          phase: phase,
          look: CharacterLook.standard,
          faceRight: faceRight,
        ),
      ),
    );

    testWidgets('dibuja dos piernas y dos brazos', (tester) async {
      await tester.pumpWidget(app(const AlwaysStoppedAnimation(0.3)));

      final assets = tester
          .widgetList<CharacterLayer>(find.byType(CharacterLayer))
          .map((layer) => layer.asset)
          .toList();
      for (final piece in ['muslo', 'rodilla', 'brazo', 'mano']) {
        expect(
          assets.where((a) => a.endsWith('${piece}_relleno.png')),
          hasLength(2),
          reason: piece,
        );
      }
      expect(
        assets.where((a) => a.endsWith('torso_relleno.png')),
        hasLength(1),
      );
    });

    Future<List<String>> assetsWith(
      WidgetTester tester,
      PantsStyle pants,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 300,
            child: WalkingCharacter(
              phase: const AlwaysStoppedAnimation(0.3),
              look: CharacterLook.standard.copyWith(pants: pants),
            ),
          ),
        ),
      );
      return tester
          .widgetList<CharacterLayer>(find.byType(CharacterLayer))
          .map((layer) => layer.asset)
          .toList();
    }

    testWidgets('el pantalón largo: muslo y rodilla sobre las piernas', (
      tester,
    ) async {
      final assets = await assetsWith(tester, PantsStyle.jeans);
      int at(String name, {bool last = false}) => last
          ? assets.lastIndexWhere((a) => a.endsWith(name))
          : assets.indexWhere((a) => a.endsWith(name));
      // Una de cada para las dos piernas.
      expect(
        assets.where((a) => a.endsWith('pantalon_2_muslo.png')),
        hasLength(2),
      );
      expect(
        assets.where((a) => a.endsWith('pantalon_2_rodilla.png')),
        hasLength(2),
      );
      expect(
        assets.where((a) => a.endsWith('pantalon_2_cadera.png')),
        hasLength(1),
      );
      // En la pierna cercana: pantorrilla del personaje < pantalón del
      // muslo < pantalón de la rodilla.
      final shin = at('rodilla_relleno.png', last: true);
      final pantsThigh = at('pantalon_2_muslo.png', last: true);
      final pantsKnee = at('pantalon_2_rodilla.png', last: true);
      expect(pantsThigh, greaterThan(shin));
      expect(pantsKnee, greaterThan(pantsThigh));
      // La cadera va debajo del muslo de la pierna cercana.
      expect(
        at('pantalon_2_cadera.png'),
        lessThan(at('muslo_relleno.png', last: true)),
      );
    });

    testWidgets('las bermudas no tienen capa de rodilla', (tester) async {
      final assets = await assetsWith(tester, PantsStyle.cargo);
      expect(assets.where((a) => a.contains('pantalon_3_muslo')), hasLength(2));
      expect(assets.where((a) => a.contains('pantalon_3_rodilla')), isEmpty);
    });

    testWidgets('la falda va sobre las piernas y no se mueve con ellas', (
      tester,
    ) async {
      final assets = await assetsWith(tester, PantsStyle.tutu);
      expect(assets.where((a) => a.contains('pantalon_10_')), hasLength(1));
      expect(
        assets.indexWhere((a) => a.endsWith('pantalon_10_cadera.png')),
        greaterThan(
          assets.lastIndexWhere((a) => a.endsWith('muslo_relleno.png')),
        ),
      );
    });

    testWidgets('sin dibujo de lado no se ve el pantalón', (tester) async {
      final assets = await assetsWith(tester, PantsStyle.golden);
      expect(assets.where((a) => a.contains('pantalon')), isEmpty);
    });

    testWidgets('solo mueve sus capas: no las vuelve a armar', (tester) async {
      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 700),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(app(controller));
      List<CharacterLayer> layers() => tester
          .widgetList<CharacterLayer>(find.byType(CharacterLayer))
          .toList();
      final before = layers();
      final first = tester
          .widgetList<Transform>(find.byType(Transform))
          .map((t) => t.transform.clone())
          .toList();

      controller.value = 0.3;
      await tester.pump();

      final after = layers();
      expect(after, hasLength(before.length));
      for (var i = 0; i < before.length; i++) {
        expect(identical(before[i], after[i]), isTrue);
      }
      final moved = tester
          .widgetList<Transform>(find.byType(Transform))
          .map((t) => t.transform)
          .toList();
      expect(moved, isNot(first));
    });

    testWidgets('se voltea cuando camina hacia la izquierda', (tester) async {
      // Cada pieza se voltea por separado (el arte mira a la derecha).
      int mirrored() => tester
          .widgetList<Transform>(find.byType(Transform))
          .where((t) => t.alignment == Alignment.center)
          .where((t) => t.transform.storage[0] == -1)
          .length;

      await tester.pumpWidget(
        app(const AlwaysStoppedAnimation(0), faceRight: true),
      );
      expect(mirrored(), 0);
      await tester.pumpWidget(
        app(const AlwaysStoppedAnimation(0), faceRight: false),
      );
      expect(mirrored(), greaterThan(0));
    });
  });

  group('el arte de lado', () {
    bool exists(String asset) => File(asset).existsSync();

    test('todos los ojos y bocas tienen sus capas en las dos vistas', () {
      // De espalda no se ve la cara, así que no tiene ojos ni bocas.
      for (final view in CharacterView.values.where(
        (v) => v != CharacterView.espalda,
      )) {
        for (final eyes in EyeStyle.values) {
          expect(
            exists(eyes.tintedAssetIn(view)),
            isTrue,
            reason: '$eyes $view',
          );
          final fill = eyes.fillAssetIn(view);
          if (fill != null) expect(exists(fill), isTrue, reason: '$eyes $view');
        }
        for (final mouth in MouthStyle.values) {
          for (final layer in mouth.layersIn(view)) {
            expect(exists(layer.asset), isTrue, reason: '$mouth $view');
          }
        }
      }
    });

    test('están las piezas del cuerpo de lado y la cabeza', () {
      for (final piece in ['torso', 'muslo', 'rodilla', 'brazo', 'mano']) {
        for (final layer in ['relleno', 'linea']) {
          expect(
            exists('assets/images/personaje/lado/cuerpo/${piece}_$layer.png'),
            isTrue,
            reason: '$piece $layer',
          );
        }
      }
    });
  });

  group('el reposo de lado', () {
    const idle = SideIdle();

    test('se repite sin saltos y las piernas no se mueven', () {
      final start = idle.poseAt(0);
      final end = idle.poseAt(1);
      expect(end.headDy, closeTo(start.headDy, 1e-9));
      expect(end.nearArm, closeTo(start.nearArm, 1e-9));
      for (var i = 0; i <= 20; i++) {
        final pose = idle.poseAt(i / 20);
        expect(pose.nearThigh, 0);
        expect(pose.farThigh, 0);
        expect(pose.nearKnee, 0);
        expect(pose.bodyDy, 0);
      }
    });

    test('respira: la cabeza sube y el torso se estira', () {
      final up = idle.poseAt(0.5);
      expect(up.headDy, lessThan(0));
      expect(up.torsoScale, greaterThan(1));
      expect(idle.poseAt(0).torsoScale, closeTo(1, 1e-9));
    });

    testWidgets('se dibuja con el personaje de lado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 300,
            child: WalkingCharacter(
              phase: const AlwaysStoppedAnimation(0.5),
              look: CharacterLook.standard,
              cycle: idle,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
