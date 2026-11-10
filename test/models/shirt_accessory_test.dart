import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('las camisas', () {
    test('la camisa de inicio es la 1 azul y es la única gratis', () {
      expect(ShirtStyle.defaultStyle, ShirtStyle.blue);
      expect(ShirtStyle.blue.id, 1);
      expect(
        [
          for (final s in ShirtStyle.values)
            if (s.isFree) s,
        ],
        [ShirtStyle.blue],
      );
    });

    test('la camisa 1 tiene 9 colores y se tiñe; las demás no', () {
      final basic = ShirtStyle.values.where((s) => s.art == 1).toList();
      expect(basic, hasLength(9));
      expect(basic.every((s) => s.tint != null), isTrue);
      expect(basic.map((s) => s.tint).toSet(), hasLength(9));
      expect(basic.where((s) => !s.isFree), hasLength(8));
      expect(
        ShirtStyle.values.where((s) => s.art != 1).every((s) => s.tint == null),
        isTrue,
      );
    });

    test('los ids no se repiten y se buscan por id', () {
      final ids = ShirtStyle.values.map((s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final style in ShirtStyle.values) {
        expect(ShirtStyle.fromId(style.id), style);
      }
      // Un id que ya no existe vuelve a la camisa de inicio.
      expect(ShirtStyle.fromId(999), ShirtStyle.blue);
      expect(ShirtStyle.fromId(null), ShirtStyle.blue);
    });

    test('cada camisa de la Tienda tiene nombre, descripción y precio', () {
      for (final style in ShirtStyle.values.where((s) => !s.isFree)) {
        expect(style.title, isNotEmpty);
        expect(style.description, isNotEmpty);
        expect(style.price, greaterThan(0));
      }
    });

    test('la camisa 2 no tiene mangas y la 5 se ve distinta de cada lado', () {
      expect(ShirtStyle.stripe.hasSleeves, isFalse);
      expect(ShirtStyle.stripe.frontSleeve(left: true), isNull);
      expect(ShirtStyle.stripe.sideSleeve, isNull);

      expect(
        ShirtStyle.clown.bodyAsset(CharacterView.lado, faceRight: true),
        endsWith('lado/camisas/camisa_5_derecha.png'),
      );
      expect(
        ShirtStyle.clown.bodyAsset(CharacterView.lado, faceRight: false),
        endsWith('lado/camisas/camisa_5_izquierda.png'),
      );
      // Las demás usan el mismo dibujo hacia los dos lados.
      expect(
        ShirtStyle.greenSoccer.bodyAsset(CharacterView.lado, faceRight: false),
        endsWith('lado/camisas/camisa_3.png'),
      );
    });

    test('existen todos los dibujos de cada camisa, de frente y de lado', () {
      bool exists(String asset) => File(asset).existsSync();
      for (final style in ShirtStyle.values) {
        expect(
          exists(style.bodyAsset(CharacterView.frente)),
          isTrue,
          reason: '${style.name} de frente',
        );
        for (final faceRight in [true, false]) {
          expect(
            exists(style.bodyAsset(CharacterView.lado, faceRight: faceRight)),
            isTrue,
            reason: '${style.name} de lado (derecha: $faceRight)',
          );
        }
        for (final left in [true, false]) {
          final sleeve = style.frontSleeve(left: left);
          if (sleeve != null) {
            expect(exists(sleeve), isTrue, reason: '${style.name} $sleeve');
          }
        }
        final side = style.sideSleeve;
        if (side != null) expect(exists(side), isTrue, reason: side);
      }
    });
  });

  group('los accesorios', () {
    test('ninguno es gratis y todos tienen nombre y precio', () {
      for (final style in AccessoryStyle.values) {
        expect(style.isFree, isFalse);
        expect(style.title, isNotEmpty);
        expect(style.description, isNotEmpty);
        expect(style.price, greaterThan(0));
      }
    });

    test('se buscan por id y el 0 es "ninguno"', () {
      for (final style in AccessoryStyle.values) {
        expect(AccessoryStyle.fromId(style.id), style);
      }
      expect(AccessoryStyle.fromId(0), isNull);
      expect(AccessoryStyle.fromId(null), isNull);
    });

    test('existen los dibujos, de frente y de lado', () {
      for (final style in AccessoryStyle.values) {
        for (final view in CharacterView.values) {
          expect(
            File(style.assetFor(view)).existsSync(),
            isTrue,
            reason: '${style.name} $view',
          );
        }
      }
      // El de lado de las orejas es otro; la gorguera usa el mismo.
      expect(
        AccessoryStyle.ogre.assetFor(CharacterView.lado),
        isNot(AccessoryStyle.ogre.assetFor(CharacterView.frente)),
      );
      expect(
        AccessoryStyle.jester.assetFor(CharacterView.lado),
        AccessoryStyle.jester.assetFor(CharacterView.frente),
      );
    });
  });

  group('el color de los accesorios', () {
    test('solo las orejas de ogro toman el tono de piel', () {
      expect(AccessoryStyle.ogre.skinTinted, isTrue);
      expect(AccessoryStyle.jester.skinTinted, isFalse);
    });
  });

  // En Windows File.existsSync no distingue mayúsculas, pero Android sí: un
  // archivo "Camisa_13.png" no se encuentra como "camisa_13.png" y la camisa se
  // dibuja sin cuerpo. Por eso se compara el nombre exacto.
  test('los nombres de los archivos de arte coinciden en mayúsculas', () {
    final assets = <String>{
      for (final shirt in ShirtStyle.values) ...[
        shirt.bodyAsset(CharacterView.frente),
        shirt.bodyAsset(CharacterView.lado, faceRight: true),
        shirt.bodyAsset(CharacterView.lado, faceRight: false),
        ?shirt.frontSleeve(left: true),
        ?shirt.frontSleeve(left: false),
        ?shirt.sideSleeve,
      ],
      for (final accessory in AccessoryStyle.values)
        for (final view in CharacterView.values) accessory.assetFor(view),
    };
    for (final asset in assets) {
      final file = File(asset);
      final names = file.parent.listSync().map(
        (e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last,
      );
      expect(
        names,
        contains(file.uri.pathSegments.last),
        reason: 'Mayúsculas distintas en $asset',
      );
    }
  });

  group('los precios coinciden con firestore.rules', () {
    final rules = File('firestore.rules').readAsStringSync();

    /// Lee `function <name>(...) { return {'1': 30, ...}.get(...` de las
    /// reglas.
    Map<int, int> pricesIn(String name) {
      final body = RegExp(
        'function $name\\([^)]*\\)\\s*\\{\\s*return\\s*\\{([^}]*)\\}',
      ).firstMatch(rules);
      expect(body, isNotNull, reason: 'No encontré $name en las reglas');
      return {
        for (final pair in RegExp(r"'(\d+)'\s*:\s*(\d+)").allMatches(body![1]!))
          int.parse(pair[1]!): int.parse(pair[2]!),
      };
    }

    test('ojos', () {
      expect(pricesIn('eyesPrice'), {
        for (final s in EyeStyle.values)
          if (!s.isFree) s.id: s.price,
      });
    });

    test('bocas', () {
      expect(pricesIn('mouthPrice'), {
        for (final s in MouthStyle.values)
          if (!s.isFree) s.id: s.price,
      });
    });

    test('camisas', () {
      expect(pricesIn('shirtPrice'), {
        for (final s in ShirtStyle.values)
          if (!s.isFree) s.id: s.price,
      });
    });

    test('accesorios', () {
      expect(pricesIn('accessoryPrice'), {
        for (final s in AccessoryStyle.values) s.id: s.price,
      });
    });

    test('la camisa y el accesorio de inicio que aceptan las reglas', () {
      expect(rules, contains('request.resource.data.shirt == 1'));
      expect(rules, contains('request.resource.data.accessory == 0'));
      expect(ShirtStyle.defaultStyle.id, 1);
    });
  });

  // Las carpetas de arte hay que declararlas en pubspec.yaml: si falta una,
  // los dibujos existen en el disco pero la app no los empaqueta (y el
  // personaje se ve sin ellos, en silencio).
  test(
    'todo el arte de camisas y accesorios está declarado en pubspec.yaml',
    () async {
      final assets = <String>{
        for (final shirt in ShirtStyle.values) ...[
          shirt.bodyAsset(CharacterView.frente),
          shirt.bodyAsset(CharacterView.lado, faceRight: true),
          shirt.bodyAsset(CharacterView.lado, faceRight: false),
          ?shirt.frontSleeve(left: true),
          ?shirt.frontSleeve(left: false),
          ?shirt.sideSleeve,
        ],
        for (final accessory in AccessoryStyle.values)
          for (final view in CharacterView.values) accessory.assetFor(view),
      };
      for (final asset in assets) {
        await rootBundle.load(asset); // Lanza si no está empaquetado.
      }
    },
  );

  group('en el perfil', () {
    const profile = UserProfile(
      uid: 'u',
      email: 'a@b.co',
      username: 'abc',
      friendCode: 'XYZ789',
      shirt: ShirtStyle.red,
      ownedShirts: {101, 3},
      accessory: AccessoryStyle.ogre,
      ownedAccessories: {1},
    );

    test('la camisa y el accesorio se guardan y se leen de Firestore', () {
      final map = profile.toMap();
      expect(map['shirt'], 101);
      expect(map['ownedShirts'], [3, 101]);
      expect(map['accessory'], 1);
      expect(map['ownedAccessories'], [1]);

      final read = UserProfile.fromMap('u', map);
      expect(read.shirt, ShirtStyle.red);
      expect(read.ownedShirts, {3, 101});
      expect(read.accessory, AccessoryStyle.ogre);
      expect(read.ownedAccessories, {1});
    });

    test('sin accesorio se guarda 0 y se lee como ninguno', () {
      const naked = UserProfile(
        uid: 'u',
        email: 'a@b.co',
        username: 'abc',
        friendCode: 'XYZ789',
      );
      expect(naked.toMap()['accessory'], 0);
      expect(UserProfile.fromMap('u', naked.toMap()).accessory, isNull);
    });

    test('un perfil viejo, sin esos campos, tiene la camisa de inicio', () {
      final read = UserProfile.fromMap('u', {'username': 'abc'});
      expect(read.shirt, ShirtStyle.blue);
      expect(read.accessory, isNull);
      expect(read.ownedShirts, isEmpty);
      expect(read.ownsShirt(ShirtStyle.blue), isTrue);
      expect(read.ownsShirt(ShirtStyle.red), isFalse);
      expect(read.ownsAccessory(AccessoryStyle.ogre), isFalse);
    });

    test('tiene la gratis, las compradas, y se quita el accesorio', () {
      expect(profile.ownsShirt(ShirtStyle.blue), isTrue);
      expect(profile.ownsShirt(ShirtStyle.red), isTrue);
      expect(profile.ownsShirt(ShirtStyle.greenSoccer), isTrue);
      expect(profile.ownsShirt(ShirtStyle.clown), isFalse);
      expect(profile.ownsAccessory(AccessoryStyle.ogre), isTrue);
      expect(profile.ownsAccessory(AccessoryStyle.jester), isFalse);
      expect(profile.copyWith(clearAccessory: true).accessory, isNull);
    });
  });

  group('dibujadas en el personaje', () {
    Future<List<CharacterLayer>> layersOf(
      WidgetTester tester, {
      required ShirtStyle shirt,
      AccessoryStyle? accessory,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 300,
            child: AnimatedCharacter(
              skinTone: Colors.brown,
              shirt: shirt,
              accessory: accessory,
            ),
          ),
        ),
      );
      return tester
          .widgetList<CharacterLayer>(find.byType(CharacterLayer))
          .toList();
    }

    testWidgets('la camisa va en el cuerpo y las mangas en los brazos', (
      tester,
    ) async {
      final layers = await layersOf(tester, shirt: ShirtStyle.greenSoccer);
      final assets = layers.map((l) => l.asset).toList();
      expect(assets, contains(endsWith('frente/camisas/camisa_3.png')));
      expect(
        assets,
        contains(endsWith('frente/camisas/manga_3_izquierda.png')),
      );
      expect(assets, contains(endsWith('frente/camisas/manga_3_derecha.png')));
    });

    testWidgets('la camisa 1 se tiñe con su color y sus mangas también', (
      tester,
    ) async {
      final layers = await layersOf(tester, shirt: ShirtStyle.red);
      final shirtLayers = layers.where(
        (l) => l.asset.contains('frente/camisas/'),
      );
      expect(shirtLayers, hasLength(3));
      expect(shirtLayers.every((l) => l.tint == ShirtStyle.red.tint), isTrue);
    });

    testWidgets('la camisa 2 no dibuja mangas', (tester) async {
      final layers = await layersOf(tester, shirt: ShirtStyle.stripe);
      final shirtLayers = layers.where(
        (l) => l.asset.contains('frente/camisas/'),
      );
      expect(shirtLayers.map((l) => l.asset), [
        endsWith('frente/camisas/camisa_2.png'),
      ]);
    });

    testWidgets('el accesorio va con la cabeza y sin él no se dibuja', (
      tester,
    ) async {
      var layers = await layersOf(
        tester,
        shirt: ShirtStyle.blue,
        accessory: AccessoryStyle.jester,
      );
      expect(
        layers.any((l) => l.asset.endsWith('accesorios/buffon.png')),
        isTrue,
      );

      layers = await layersOf(tester, shirt: ShirtStyle.blue);
      expect(layers.any((l) => l.asset.contains('accesorios/')), isFalse);
    });
  });
}
