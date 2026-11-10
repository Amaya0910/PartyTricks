import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';
import 'package:party_tricks/widgets/pants_picker.dart';

void main() {
  group('los pantalones', () {
    test('hay 21, con ids seguidos, y ninguno es gratis', () {
      expect(PantsStyle.values, hasLength(21));
      expect(PantsStyle.values.map((p) => p.id), [
        for (var i = 1; i <= 21; i++) i,
      ]);
      expect(PantsStyle.golden.id, 1);
      expect(PantsStyle.values.every((p) => !p.isFree), isTrue);
      expect(PantsStyle.values.map((p) => p.title).toSet(), hasLength(21));
    });

    test('hay de todos los largos y de todas las rarezas', () {
      expect(
        PantsStyle.values.map((p) => p.cut).toSet(),
        PantsCut.values.toSet(),
      );
      expect(
        PantsStyle.values.where((p) => p.cut == PantsCut.skirt),
        hasLength(3),
      );
      expect(PantsStyle.neon.rarity.level, 5);
    });

    test('el dorado solo tiene dibujo de frente', () {
      expect(PantsStyle.golden.sideArt, isFalse);
      expect(PantsStyle.golden.assetFor(CharacterView.lado), isNull);
      expect(PantsStyle.golden.sideThighAsset, isNull);
    });

    test('cada capa existe, con su nombre exacto, y está declarada', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // En Android los nombres distinguen mayúsculas: se compara el nombre
      // tal como está en la carpeta.
      Set<String> names(String dir) =>
          Directory(dir).listSync().map((e) => e.uri.pathSegments.last).toSet();
      final front = names('assets/images/personaje/frente/pantalones');
      final side = names('assets/images/personaje/lado/pantalones');
      for (final p in PantsStyle.values) {
        final frontAsset = p.assetFor(CharacterView.frente)!;
        expect(front, contains(frontAsset.split('/').last), reason: p.title);
        await rootBundle.load(frontAsset);
        for (final asset in [
          p.sideHipAsset,
          p.sideThighAsset,
          p.sideKneeAsset,
        ]) {
          if (asset == null) continue;
          expect(side, contains(asset.split('/').last), reason: p.title);
          await rootBundle.load(asset);
        }
      }
    });

    test('las capas de lado dependen del largo', () {
      expect(PantsStyle.jeans.sideKneeAsset, isNotNull);
      expect(PantsStyle.jeans.sideThighAsset, isNotNull);
      expect(PantsStyle.cargo.sideKneeAsset, isNull);
      expect(PantsStyle.cargo.sideThighAsset, isNotNull);
      expect(PantsStyle.tutu.sideThighAsset, isNull);
      expect(PantsStyle.tutu.sideKneeAsset, isNull);
      expect(PantsStyle.tutu.sideHipAsset, isNotNull);
      expect(PantsStyle.tutu.hipOverLegs, isTrue);
      expect(PantsStyle.jeans.hipOverLegs, isFalse);
    });

    test('el precio coincide con firestore.rules', () {
      final rules = File('firestore.rules').readAsStringSync();
      final body = RegExp(
        r'function pantsPrice\([^)]*\)\s*\{\s*return\s*\{([^}]*)\}',
      ).firstMatch(rules);
      expect(body, isNotNull);
      final prices = {
        for (final pair in RegExp(r"'(\d+)'\s*:\s*(\d+)").allMatches(body![1]!))
          int.parse(pair[1]!): int.parse(pair[2]!),
      };
      expect(prices, {for (final p in PantsStyle.values) p.id: p.price});
      expect(rules, contains('request.resource.data.pants == 0'));
    });
  });

  test('el pantalón se guarda en el perfil', () {
    const profile = UserProfile(
      uid: 'u',
      email: 'a@b.c',
      username: 'x',
      friendCode: 'ABC',
      pants: PantsStyle.golden,
      ownedPants: {1},
    );
    final read = UserProfile.fromMap('u', profile.toMap());
    expect(read.pants, PantsStyle.golden);
    expect(read.ownsPants(PantsStyle.golden), isTrue);
    expect(
      UserProfile.fromMap('u', {...profile.toMap(), 'pants': 0}).pants,
      isNull,
    );
  });

  testWidgets('el personaje lo lleva sobre las piernas', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 400,
          child: AnimatedCharacter.fromLook(
            CharacterLook(
              skinTone: Colors.brown,
              eyeColor: Colors.white,
              pants: PantsStyle.golden,
            ),
          ),
        ),
      ),
    );
    final assets = t
        .widgetList<CharacterLayer>(find.byType(CharacterLayer))
        .map((l) => l.asset)
        .toList();
    final pants = assets.indexWhere((a) => a.endsWith('pantalon_1.png'));
    final leg = assets.lastIndexWhere((a) => a.contains('pierna_derecha'));
    expect(pants, greaterThan(leg));
  });

  testWidgets('el selector tiene "Ninguno" con una X roja', (t) async {
    PantsStyle? picked = PantsStyle.golden;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PantsPicker(
            styles: PantsStyle.values,
            selectedStyle: picked,
            onStyleSelected: (s) => picked = s,
            skin: Colors.brown,
          ),
        ),
      ),
    );
    expect(find.byType(NoneMark), findsOneWidget);
    await t.tap(find.byType(NoneMark));
    expect(picked, isNull);
    expect(find.byType(PantsThumbnail), findsWidgets);
  });
}
