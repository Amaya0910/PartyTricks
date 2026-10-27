import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/services/shop/chest_roller.dart';

import '../game_engine/fake_random_source.dart';

void main() {
  const roller = ChestRoller();

  test('el cofre básico reparte los premios según sus porcentajes', () {
    // 25 % cosmético, 5 % nada, 65 % monedas, 5 % dado.
    final random = FakeRandomSource([25, 26, 30, 31, 95, 96, 100]);
    final outcomes = [
      for (var i = 0; i < 7; i++)
        roller.roll(ChestType.basic.odds, random),
    ];

    expect(outcomes, [
      ChestOutcome.cosmetic,
      ChestOutcome.nothing,
      ChestOutcome.nothing,
      ChestOutcome.coins,
      ChestOutcome.coins,
      ChestOutcome.dice,
      ChestOutcome.dice,
    ]);
  });

  test('un premio con 0 % nunca sale', () {
    final random = FakeRandomSource([1, 50, 51, 100]);
    final outcomes = [
      for (var i = 0; i < 4; i++)
        roller.roll(ChestType.diamond.odds, random),
    ];

    expect(outcomes, [
      ChestOutcome.cosmetic,
      ChestOutcome.cosmetic,
      ChestOutcome.dice,
      ChestOutcome.dice,
    ]);
  });
}