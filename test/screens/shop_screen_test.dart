import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/eyes_controller.dart';
import 'package:party_tricks/controllers/mouth_controller.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/screens/shop_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';
import 'package:party_tricks/services/shop/shop_providers.dart';
import 'package:party_tricks/services/shop/shop_service.dart';

/// Tienda en memoria: cobra y guarda los ojos en el perfil que emite.
class _FakeShopService implements ShopService {
  _FakeShopService(this.profiles, UserProfile start) : _profile = start;

  final StreamController<UserProfile> profiles;
  UserProfile _profile;

  @override
  Future<ChestPrize> buyChest({
    required String uid,
    required ChestType chest,
  }) async => const ChestPrize(ChestOutcome.nothing);

  @override
  Future<void> buyEyes({required String uid, required EyeStyle eyes}) async {
    if (_profile.coins < eyes.price) {
      throw const ShopException('No tienes suficientes monedas.');
    }
    _profile = _profile.copyWith(
      coins: _profile.coins - eyes.price,
      ownedEyes: {..._profile.ownedEyes, eyes.number},
    );
    profiles.add(_profile);
  }

  @override
  Future<void> buyMouth({
    required String uid,
    required MouthStyle mouth,
  }) async {
    if (_profile.coins < mouth.price) {
      throw const ShopException('No tienes suficientes monedas.');
    }
    _profile = _profile.copyWith(
      coins: _profile.coins - mouth.price,
      ownedMouths: {..._profile.ownedMouths, mouth.number},
    );
    profiles.add(_profile);
  }
}

void main() {
  const start = UserProfile(
    uid: 'me',
    email: 'tay@correo.com',
    username: 'Tay',
    friendCode: 'ABC234',
    coins: 50,
    ownedEyes: {3},
  );

  late StreamController<UserProfile> profiles;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    profiles = StreamController<UserProfile>.broadcast();
    addTearDown(profiles.close);
    final shop = _FakeShopService(profiles, start);
    container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith((ref) async* {
          yield start;
          yield* profiles.stream;
        }),
        shopServiceProvider.overrideWithValue(shop),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ShopScreen())),
      ),
    );
    await tester.pump();
  }

  testWidgets('muestra solo los ojos que no tienes, con su precio', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(EyeStyle.ojo1.title), findsOneWidget);
    expect(find.text(EyeStyle.ojo11.title), findsOneWidget);
    // Los gratis y los comprados no se venden.
    expect(find.text(EyeStyle.ojo7.title), findsNothing);
    expect(find.text(EyeStyle.ojo3.title), findsNothing);
  });

  testWidgets('muestra las bocas que no tienes, con su nombre', (tester) async {
    await pump(tester);
    expect(find.text(MouthStyle.boca2.title), findsOneWidget);
    expect(find.text(MouthStyle.boca10.title), findsOneWidget);
    // Las bocas 1 y 3 son gratis y no se venden.
    expect(find.text(MouthStyle.boca1.title), findsNothing);
    expect(find.text(MouthStyle.boca3.title), findsNothing);
  });

  testWidgets('el filtro muestra solo ojos o solo bocas', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Bocas'));
    await tester.pump();
    expect(find.text(MouthStyle.boca2.title), findsOneWidget);
    expect(find.text(EyeStyle.ojo1.title), findsNothing);

    await tester.tap(find.text('Ojos'));
    await tester.pump();
    expect(find.text(EyeStyle.ojo1.title), findsOneWidget);
    expect(find.text(MouthStyle.boca2.title), findsNothing);

    await tester.tap(find.text('Todos'));
    await tester.pump();
    expect(find.text(EyeStyle.ojo1.title), findsOneWidget);
    expect(find.text(MouthStyle.boca2.title), findsOneWidget);
  });

  testWidgets('se puede ordenar por precio y por rareza', (tester) async {
    await pump(tester);
    double top(String title) => tester.getTopLeft(find.text(title)).dy;

    await tester.tap(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Precio: mayor a menor'));
    await tester.pumpAndSettle();
    // Ojos Pícaros (100) arriba de Ojos Pequeñitos (30).
    expect(top(EyeStyle.ojo11.title), lessThan(top(EyeStyle.ojo1.title)));

    await tester.tap(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rareza: menor a mayor'));
    await tester.pumpAndSettle();
    expect(top(EyeStyle.ojo1.title), lessThan(top(EyeStyle.ojo11.title)));
  });

  testWidgets('comprar una boca la quita de la Tienda', (tester) async {
    await pump(tester);
    await tester.tap(find.text(MouthStyle.boca2.title));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tienes 50 monedas'), findsOneWidget);

    await tester.tap(find.text('Comprar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(ownedMouthsProvider), contains(MouthStyle.boca2));
    expect(
      container.read(mouthsForSaleProvider),
      isNot(contains(MouthStyle.boca2)),
    );
    expect(find.text(MouthStyle.boca2.description), findsNothing);
  });

  testWidgets('no deja ponerse una boca que no se ha comprado', (tester) async {
    await pump(tester);
    await expectLater(
      container.read(mouthControllerProvider).selectStyle(MouthStyle.boca8),
      throwsA(isA<CharacterException>()),
    );
  });

  testWidgets('comprar unos ojos los quita de la Tienda', (tester) async {
    await pump(tester);
    await tester.tap(find.text(EyeStyle.ojo1.title));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tienes 50 monedas'), findsOneWidget);

    await tester.tap(find.text('Comprar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(ownedEyesProvider), contains(EyeStyle.ojo1));
    expect(
      find.text('¡Ya tienes los Ojos Pequeñitos! Póntelos en el Vestuario'),
      findsOneWidget,
    );
    expect(find.text(EyeStyle.ojo1.description), findsNothing);
  });

  testWidgets('si no alcanzan las monedas, no deja comprar', (tester) async {
    await pump(tester);
    await tester.tap(find.text(EyeStyle.ojo11.title));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Te faltan 50 monedas'), findsOneWidget);

    await tester.tap(find.text('Comprar'));
    await tester.pump();
    expect(container.read(ownedEyesProvider), isNot(contains(EyeStyle.ojo11)));
  });

  testWidgets('no deja ponerse ojos que no se han comprado', (tester) async {
    await pump(tester);
    await expectLater(
      container.read(eyesControllerProvider).selectStyle(EyeStyle.ojo8),
      throwsA(isA<CharacterException>()),
    );
  });
}
