import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/hair_color.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/widgets/accessory_picker.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';
import 'package:party_tricks/widgets/hair_picker.dart';

void main() {
  group('los cabellos', () {
    test('hay 11, con ids distintos y ninguno gratis', () {
      expect(HairStyle.values, hasLength(11));
      expect({for (final h in HairStyle.values) h.id}, hasLength(11));
      // La peluca de payaso es lo más caro y lo más raro, y trae sus colores.
      final wig = HairStyle.clownWig;
      expect(wig.rarity.level, Rarity.values.last.level);
      expect(
        HairStyle.values.every((h) => h == wig || h.price < wig.price),
        isTrue,
      );
      expect(wig.tintable, isFalse);
      expect(HairStyle.values.every((h) => !h.isFree && h.price > 0), isTrue);
    });

    test('existen los dibujos, de frente y de lado, y las partes de atrás', () {
      for (final style in HairStyle.values) {
        for (final view in CharacterView.values) {
          expect(
            File(style.assetFor(view)).existsSync(),
            isTrue,
            reason: '$style',
          );
          final back = style.backAssetFor(view);
          if (back != null) {
            expect(File(back).existsSync(), isTrue, reason: back);
          }
        }
        expect(style.backAssetFor(CharacterView.lado), isNull);
      }
      expect(HairStyle.values.where((h) => h.hasBackInFront).map((h) => h.id), [
        1,
        3,
        6,
      ]);
    });

    test('solo los blancos se pueden teñir', () {
      expect(HairStyle.values.where((h) => h.tintable).map((h) => h.id), [
        2,
        6,
        7,
        9,
      ]);
      final blue = CharacterLook(
        skinTone: Colors.brown,
        eyeColor: Colors.white,
        hair: HairStyle.tufts,
        hairColor: 5,
      );
      expect(blue.hairTint, isNull);
      expect(
        blue.copyWith(hair: HairStyle.clouds).hairTint,
        HairColor.colorOf(5),
      );
      expect(blue.copyWith(clearHair: true).hairTint, isNull);
    });

    test('todo el arte está declarado en pubspec.yaml', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final style in HairStyle.values) {
        for (final view in CharacterView.values) {
          await rootBundle.load(style.assetFor(view));
          final back = style.backAssetFor(view);
          if (back != null) await rootBundle.load(back);
        }
      }
    });

    test('los precios coinciden con firestore.rules', () {
      final rules = File('firestore.rules').readAsStringSync();
      final body = RegExp(
        r'function hairPrice\([^)]*\)\s*\{\s*return\s*\{([^}]*)\}',
      ).firstMatch(rules);
      expect(body, isNotNull);
      final prices = {
        for (final pair in RegExp(r"'(\d+)'\s*:\s*(\d+)").allMatches(body![1]!))
          int.parse(pair[1]!): int.parse(pair[2]!),
      };
      expect(prices, {for (final h in HairStyle.values) h.id: h.price});
      expect(rules, contains('request.resource.data.hair == 0'));
    });
  });

  group('el cabello en el perfil', () {
    test('se guarda y se lee, con su color y los comprados', () {
      const profile = UserProfile(
        uid: 'u',
        email: 'a@b.c',
        username: 'x',
        friendCode: 'ABC',
        hair: HairStyle.mane,
        ownedHairs: {6},
        hairColor: 7,
      );
      final read = UserProfile.fromMap('u', profile.toMap());
      expect(read.hair, HairStyle.mane);
      expect(read.hairColor, 7);
      expect(read.ownsHair(HairStyle.mane), isTrue);
      expect(read.ownsHair(HairStyle.clouds), isFalse);
    });

    test('sin cabello se guarda 0 y se lee null', () {
      const profile = UserProfile(
        uid: 'u',
        email: 'a@b.c',
        username: 'x',
        friendCode: 'ABC',
      );
      expect(profile.toMap()['hair'], 0);
      expect(UserProfile.fromMap('u', profile.toMap()).hair, isNull);
      expect(profile.hairColor, HairColor.defaultIndex);
    });

    test('el perfil público lleva el cabello', () {
      const pub = PublicProfile(
        uid: 'u',
        username: 'x',
        friendCode: 'ABC',
        hair: HairStyle.spikes,
        hairColor: 3,
      );
      final read = PublicProfile.fromMap('u', pub.toMap());
      expect(read.hair, HairStyle.spikes);
      expect(read.hairColor, 3);
    });
  });

  group('dibujo del cabello', () {
    List<CharacterLayer> layers(WidgetTester t) =>
        t.widgetList<CharacterLayer>(find.byType(CharacterLayer)).toList();

    Future<void> show(WidgetTester t, CharacterLook look) => t.pumpWidget(
      MaterialApp(
        home: SizedBox(height: 400, child: AnimatedCharacter.fromLook(look)),
      ),
    );

    testWidgets('la parte de atrás va antes que la cabeza', (t) async {
      await show(
        t,
        CharacterLook(
          skinTone: Colors.brown,
          eyeColor: Colors.white,
          hair: HairStyle.mane,
          hairColor: 4,
        ),
      );
      final assets = layers(t).map((l) => l.asset).toList();
      final back = assets.indexWhere((a) => a.endsWith('cabello_6_atras.png'));
      final head = assets.indexWhere((a) => a.endsWith('relleno_cabeza.png'));
      final front = assets.indexWhere(
        (a) => a.endsWith('cabellos/cabello_6.png'),
      );
      final body = assets.indexWhere((a) => a.endsWith('relleno_cuerpo.png'));
      expect(back, isNonNegative);
      // Es la capa más atrás: debajo del cuerpo (que no tape el cuello).
      expect(back, lessThan(body));
      expect(back, lessThan(head));
      expect(front, greaterThan(head));
      expect(
        layers(t)
            .where((l) => l.asset.contains('cabello_6'))
            .every((l) => l.tint == HairColor.colorOf(4)),
        isTrue,
      );
    });

    testWidgets('sin cabello no se dibuja ninguno', (t) async {
      await show(t, CharacterLook.standard);
      expect(layers(t).any((l) => l.asset.contains('cabellos/')), isFalse);
    });
  });

  testWidgets('el selector tiene "Ninguno" con una X roja', (t) async {
    HairStyle? picked = HairStyle.tufts;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: HairPicker(
              styles: HairStyle.values,
              selectedStyle: picked,
              onStyleSelected: (s) => picked = s,
              skin: Colors.brown,
              colors: [for (var i = 0; i < 3; i++) HairColor.colorOf(i)],
              selectedColor: 0,
              onColorSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    // La X de "Ninguno" y la del primer color ("sin color").
    expect(find.byType(NoneMark), findsOneWidget);
    final x = find.descendant(
      of: find.byType(NoneMark),
      matching: find.byIcon(Icons.close_rounded),
    );
    expect(t.widget<Icon>(x).color, Colors.red.shade600);
    await t.tap(x);
    expect(picked, isNull);
    expect(find.byType(HairThumbnail), findsWidgets);
    expect(find.byType(AccessoryThumbnail), findsNothing);
  });
}
