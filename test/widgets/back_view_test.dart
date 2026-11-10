import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_clips.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/character/eyes_layer.dart';
import 'package:party_tricks/widgets/character/mouth_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Set<String> namesIn(String dir) =>
      Directory(dir).listSync().map((e) => e.uri.pathSegments.last).toSet();

  group('el arte de espalda', () {
    test('cada cabello tiene su dibujo de espalda y está declarado', () async {
      final names = namesIn('assets/images/personaje/espalda/cabellos');
      for (final hair in HairStyle.values) {
        final asset = hair.assetFor(CharacterView.espalda);
        expect(names, contains(asset.split('/').last), reason: hair.title);
        await rootBundle.load(asset);
        // La parte de atrás de frente no se usa de espalda.
        expect(hair.backAssetFor(CharacterView.espalda), isNull);
      }
    });

    test(
      'los pantalones tienen espalda (el dorado usa la de frente)',
      () async {
        final names = namesIn('assets/images/personaje/espalda/pantalones');
        for (final pants in PantsStyle.values) {
          final asset = pants.assetFor(CharacterView.espalda)!;
          await rootBundle.load(asset);
          if (pants == PantsStyle.golden) {
            expect(asset, pants.assetFor(CharacterView.frente));
          } else {
            expect(names, contains(asset.split('/').last), reason: pants.title);
          }
        }
      },
    );

    test('las camisas del segundo drop tienen el estampado de atrás', () async {
      final names = namesIn('assets/images/personaje/espalda/camisas');
      final drop = ShirtStyle.values.where((s) => s.hasBackArt).toList();
      expect(drop, hasLength(5));
      for (final shirt in drop) {
        final asset = shirt.bodyAsset(CharacterView.espalda);
        expect(names, contains(asset.split('/').last), reason: shirt.title);
        await rootBundle.load(asset);
      }
    });

    test('las demás camisas de espalda usan el dibujo de frente', () {
      for (final shirt in ShirtStyle.values.where((s) => !s.hasBackArt)) {
        expect(
          shirt.bodyAsset(CharacterView.espalda),
          shirt.bodyAsset(CharacterView.frente),
          reason: shirt.title,
        );
      }
    });

    test('las camisas del segundo drop tienen todas sus capas', () async {
      for (final shirt in ShirtStyle.values.where((s) => s.hasBackArt)) {
        for (final asset in [
          shirt.bodyAsset(CharacterView.frente),
          shirt.bodyAsset(CharacterView.lado),
          shirt.frontSleeve(left: true)!,
          shirt.frontSleeve(left: false)!,
          shirt.sideSleeve!,
        ]) {
          expect(File(asset).existsSync(), isTrue, reason: asset);
          await rootBundle.load(asset);
        }
      }
    });

    test('los accesorios se ven igual de espalda', () {
      for (final a in AccessoryStyle.values) {
        expect(
          a.assetFor(CharacterView.espalda),
          a.assetFor(CharacterView.frente),
        );
      }
    });
  });

  group('el personaje de espalda', () {
    Future<List<String>> assetsOf(
      WidgetTester tester,
      CharacterLook look,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 300,
            child: AnimatedCharacter.fromLook(
              look,
              view: CharacterView.espalda,
              animation: const WalkAwayAnimation(),
            ),
          ),
        ),
      );
      return tester
          .widgetList<CharacterLayer>(find.byType(CharacterLayer))
          .map((l) => l.asset)
          .toList();
    }

    testWidgets('no tiene cara: ni ojos ni boca', (tester) async {
      await assetsOf(tester, CharacterLook.standard);
      expect(find.byType(EyesLayer), findsNothing);
      expect(find.byType(MouthLayer), findsNothing);
    });

    testWidgets('lleva la ropa y el cabello de espalda', (tester) async {
      final assets = await assetsOf(
        tester,
        CharacterLook.standard.copyWith(
          shirt: ShirtStyle.shifts8,
          pants: PantsStyle.jeans,
          hair: HairStyle.wild,
        ),
      );
      const root = 'assets/images/personaje/espalda';
      expect(assets, contains('$root/camisas/camisa_17.png'));
      expect(assets, contains('$root/pantalones/pantalon_2.png'));
      expect(assets, contains('$root/cabellos/cabello_4.png'));
      // Nada de lo de frente de esas prendas.
      expect(
        assets.where((a) => a.contains('/frente/camisas/camisa_17')),
        isEmpty,
      );
      expect(assets.where((a) => a.contains('/frente/cabellos/')), isEmpty);
    });

    testWidgets('el accesorio va debajo del cabello', (tester) async {
      final assets = await assetsOf(
        tester,
        CharacterLook.standard.copyWith(
          hair: HairStyle.wild,
          accessory: AccessoryStyle.ogre,
        ),
      );
      final accessory = assets.indexWhere((a) => a.contains('/accesorios/'));
      final hair = assets.indexWhere((a) => a.contains('/espalda/cabellos/'));
      expect(accessory, isNonNegative);
      expect(hair, greaterThan(accessory));
    });

    testWidgets('de frente el accesorio sigue sobre el cabello', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 300,
            child: AnimatedCharacter.fromLook(
              CharacterLook.standard.copyWith(
                hair: HairStyle.wild,
                accessory: AccessoryStyle.ogre,
              ),
            ),
          ),
        ),
      );
      final assets = tester
          .widgetList<CharacterLayer>(find.byType(CharacterLayer))
          .map((l) => l.asset)
          .toList();
      expect(
        assets.indexWhere((a) => a.contains('/accesorios/')),
        greaterThan(assets.indexWhere((a) => a.contains('/frente/cabellos/'))),
      );
    });

    testWidgets('el pantalón va sobre las piernas', (tester) async {
      final assets = await assetsOf(
        tester,
        CharacterLook.standard.copyWith(pants: PantsStyle.cargo),
      );
      expect(
        assets.indexWhere((a) => a.endsWith('pantalon_3.png')),
        greaterThan(assets.lastIndexWhere((a) => a.contains('pierna_derecha'))),
      );
    });
  });

  group('caminar de espalda', () {
    const walk = WalkAwayAnimation();

    test('empieza y termina igual, para repetirse sin saltos', () {
      for (final part in BodyPart.values) {
        final a = walk.transformFor(part, 0);
        final b = walk.transformFor(part, 1);
        expect(b.dy, closeTo(a.dy, 1e-9), reason: '$part');
        expect(b.angle, closeTo(a.angle, 1e-9), reason: '$part');
        expect(b.scaleY, closeTo(a.scaleY, 1e-9), reason: '$part');
      }
    });

    test('las piernas se levantan una a la vez', () {
      for (var i = 0; i <= 40; i++) {
        final t = i / 40;
        final left = walk.transformFor(BodyPart.piernaIzquierda, t).dy;
        final right = walk.transformFor(BodyPart.piernaDerecha, t).dy;
        expect(left <= 0 && right <= 0, isTrue);
        // Nunca están las dos levantadas a la vez.
        expect(left.abs() < 1e-9 || right.abs() < 1e-9, isTrue, reason: 't=$t');
      }
    });

    test('el cuerpo no se estira', () {
      for (var i = 0; i <= 20; i++) {
        expect(walk.transformFor(BodyPart.cuerpo, i / 20).scaleY, 1);
      }
    });
  });

  group('las animaciones de espalda', () {
    test('están en la lista, con vista de espalda', () {
      expect(CharacterClip.idleBack.view, CharacterView.espalda);
      expect(CharacterClip.walkBack.view, CharacterView.espalda);
      expect(CharacterClip.walkBack.canFlip, isFalse);
    });
  });
}
