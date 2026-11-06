import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/user_profile.dart';

void main() {
  const profile = UserProfile(
    uid: 'u',
    email: 'a@b.co',
    username: 'abc',
    friendCode: 'XYZ789',
    ownedMouths: {4, 9},
  );

  test('las bocas 1 y 3 son gratis y la de inicio es gratis', () {
    final free = [
      for (final style in MouthStyle.values)
        if (style.isFree) style.number,
    ];
    expect(free, [1, 3]);
    expect(MouthStyle.defaultStyle, MouthStyle.boca1);
    expect(MouthStyle.defaultStyle.isFree, isTrue);
  });

  test('cada boca de la Tienda tiene nombre, descripción y precio', () {
    for (final style in MouthStyle.values.where((s) => !s.isFree)) {
      expect(style.title, isNotEmpty);
      expect(style.description, isNotEmpty);
      expect(style.price, greaterThan(0));
    }
  });

  test('tiene las gratis y las compradas', () {
    expect(profile.ownsMouth(MouthStyle.boca1), isTrue);
    expect(profile.ownsMouth(MouthStyle.boca4), isTrue);
    expect(profile.ownsMouth(MouthStyle.boca9), isTrue);
    expect(profile.ownsMouth(MouthStyle.boca2), isFalse);
  });

  test('la boca, su color y las compradas se guardan y se leen', () {
    final saved = profile.copyWith(mouth: MouthStyle.boca4, mouthColor: 7);
    final map = saved.toMap();
    expect(map['mouth'], 4);
    expect(map['mouthColor'], 7);
    expect(map['ownedMouths'], [4, 9]);
    final read = UserProfile.fromMap('u', map);
    expect(read.mouth, MouthStyle.boca4);
    expect(read.mouthColor, 7);
    expect(read.ownedMouths, {4, 9});
  });

  test('sin los campos, usa la boca 1 sin color y sin compras', () {
    final read = UserProfile.fromMap('u', {'username': 'abc'});
    expect(read.mouth, MouthStyle.boca1);
    expect(read.mouthColor, MouthColor.noColorIndex);
    expect(read.ownedMouths, isEmpty);
  });

  test('una boca que ya no existe vuelve a la de inicio', () {
    expect(MouthStyle.fromNumber(99), MouthStyle.defaultStyle);
    expect(MouthStyle.fromNumber(null), MouthStyle.defaultStyle);
  });

  test('las bocas 1, 9 y 10 no se tiñen', () {
    for (final style in [
      MouthStyle.boca1,
      MouthStyle.boca9,
      MouthStyle.boca10,
    ]) {
      expect(style.layers.every((layer) => !layer.tinted), isTrue);
    }
  });

  test('en la boca 8 se tiñe la línea, que tiene el blanco', () {
    expect(MouthStyle.boca8.layers.map((l) => l.tinted), [false, true]);
    expect(MouthStyle.boca2.layers.single.tinted, isTrue);
  });

  test('sin color no hay color elegido; con color, es de la paleta', () {
    expect(MouthColor.colorOf(MouthColor.noColorIndex), isNull);
    expect(MouthColor.count, 20);
    expect(MouthColor.colorOf(3), isNotNull);
    expect(MouthColor.clamp(99), 19);
  });

  test('la línea de colores muestra el tono de piel en la posición 0', () {
    const skin = Color(0xFFE0B090);
    final swatches = MouthColor.swatches(skin);
    expect(swatches, hasLength(MouthColor.count));
    expect(swatches.first, skin);
  });
}
