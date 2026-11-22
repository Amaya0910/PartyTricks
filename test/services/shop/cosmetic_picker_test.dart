import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/services/shop/cosmetic_picker.dart';

import '../game_engine/fake_random_source.dart';

void main() {
  const picker = CosmeticPicker();

  int totalWeight(Set<int> eyes, Set<int> mouths) {
    var total = 0;
    for (final e in EyeStyle.values) {
      if (!e.isFree && !eyes.contains(e.number)) total += e.rarity.weight;
    }
    for (final m in MouthStyle.values) {
      if (!m.isFree && !mouths.contains(m.number)) total += m.rarity.weight;
    }
    for (final s in ShirtStyle.values) {
      if (!s.isFree) total += s.rarity.weight;
    }
    for (final p in PantsStyle.values) {
      total += p.rarity.weight;
    }
    for (final h in HairStyle.values) {
      total += h.rarity.weight;
    }
    for (final a in AccessoryStyle.values) {
      total += a.rarity.weight;
    }
    return total;
  }

  test('con un 1 sale el primero de la lista y con el total, el último', () {
    final first = picker.pick(
      ownedEyes: {},
      ownedMouths: {},
      random: FakeRandomSource([1]),
    );
    expect(first!.outcome, ChestOutcome.cosmetic);
    expect(first.eyes, EyeStyle.ojo1);
    expect(first.mouth, isNull);

    final last = picker.pick(
      ownedEyes: {},
      ownedMouths: {},
      random: FakeRandomSource([totalWeight({}, {})]),
    );
    // Al final del catálogo van los accesorios.
    expect(last!.accessory, AccessoryStyle.jester);
    expect(last.eyes, isNull);
    expect(last.mouth, isNull);
  });

  test('no regala lo que ya tiene ni lo gratis', () {
    final owned = {
      for (final e in EyeStyle.values)
        if (!e.isFree) e.number,
    };
    final prize = picker.pick(
      ownedEyes: owned,
      ownedMouths: {},
      random: FakeRandomSource([1]),
    );
    expect(prize!.eyes, isNull);
    expect(prize.mouth, MouthStyle.boca2);
    expect(prize.mouth!.isFree, isFalse);
  });

  test('si ya los tiene todos, no hay cosmético', () {
    final prize = picker.pick(
      ownedEyes: {for (final e in EyeStyle.values) e.number},
      ownedMouths: {for (final m in MouthStyle.values) m.number},
      ownedShirts: {for (final s in ShirtStyle.values) s.id},
      ownedPants: {for (final p in PantsStyle.values) p.id},
      ownedHairs: {for (final h in HairStyle.values) h.id},
      ownedAccessories: {for (final a in AccessoryStyle.values) a.id},
      random: FakeRandomSource([]),
    );
    expect(prize, isNull);
  });

  test('también salen camisas y accesorios, nunca la camisa de inicio', () {
    final chances = picker.chances(ownedEyes: {}, ownedMouths: {});
    final shirts = chances.map((c) => c.shirt).whereType<ShirtStyle>().toList();
    expect(shirts, isNotEmpty);
    expect(shirts, isNot(contains(ShirtStyle.blue)));
    expect(shirts, contains(ShirtStyle.red));
    expect(
      chances.map((c) => c.accessory).whereType<AccessoryStyle>().toSet(),
      AccessoryStyle.values.toSet(),
    );
  });

  test('si ya tiene los ojos y las bocas, puede salir una camisa', () {
    final prize = picker.pick(
      ownedEyes: {for (final e in EyeStyle.values) e.number},
      ownedMouths: {for (final m in MouthStyle.values) m.number},
      random: FakeRandomSource([1]),
    );
    expect(prize!.shirt, ShirtStyle.red);
    expect(prize.cosmetic, ShirtStyle.red);
    expect(prize.eyes, isNull);
    expect(prize.accessory, isNull);
  });

  test('lo que ya tiene de camisas y accesorios no sale', () {
    final prize = picker.pick(
      ownedEyes: {for (final e in EyeStyle.values) e.number},
      ownedMouths: {for (final m in MouthStyle.values) m.number},
      ownedShirts: {
        for (final s in ShirtStyle.values)
          if (s != ShirtStyle.shifts7) s.id,
      },
      ownedAccessories: {AccessoryStyle.ogre.id},
      random: FakeRandomSource([1]),
    );
    expect(prize!.shirt, ShirtStyle.shifts7);
  });

  test('lo raro pesa menos que lo común', () {
    expect(Rarity.common.weight, greaterThan(Rarity.legendary.weight));
    for (var i = 1; i < Rarity.values.length; i++) {
      expect(Rarity.values[i].weight, lessThan(Rarity.values[i - 1].weight));
      expect(Rarity.values[i].level, Rarity.values[i - 1].level + 1);
    }
  });

  test('los ojos pícaros son legendarios y cuestan 100', () {
    expect(EyeStyle.ojo11.rarity, Rarity.legendary);
    expect(EyeStyle.ojo11.price, 100);
  });
}
