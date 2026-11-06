import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/rarity.dart';
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
    expect(last!.mouth, MouthStyle.boca10);
    expect(last.eyes, isNull);
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
      random: FakeRandomSource([]),
    );
    expect(prize, isNull);
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
