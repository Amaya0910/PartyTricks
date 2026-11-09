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
    test('hay uno, y no es gratis', () {
      expect(PantsStyle.values, hasLength(1));
      expect(PantsStyle.golden.id, 1);
      expect(PantsStyle.golden.isFree, isFalse);
    });

    test(
      'tiene dibujo de frente (todavía no de lado) y está declarado',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final asset = PantsStyle.golden.assetFor(CharacterView.frente)!;
        expect(File(asset).existsSync(), isTrue);
        await rootBundle.load(asset);
        expect(PantsStyle.golden.assetFor(CharacterView.lado), isNull);
      },
    );

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
    expect(find.byType(PantsThumbnail), findsOneWidget);
  });
}
