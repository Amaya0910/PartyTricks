import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/tile_effects.dart';

import 'fake_random_source.dart';

void main() {
  const effects = TileEffects();

  test('la positiva da monedas y la negativa quita', () {
    final random = FakeRandomSource([]);
    expect(effects.resolve(TileType.positive, random).coinDelta, 3);
    expect(effects.resolve(TileType.negative, random).coinDelta, -3);
  });

  test('en la salida y la tienda no pasa nada', () {
    final random = FakeRandomSource([]);
    for (final type in [TileType.start, TileType.shop]) {
      final outcome = effects.resolve(type, random);
      expect(outcome.coinDelta, 0);
      expect(outcome.pendingEffect, isNull);
    }
  });

  test('la especial sortea un efecto para el siguiente turno', () {
    // El primer número del sorteo es del primer efecto (dado de 3).
    final outcome = effects.resolve(TileType.special, FakeRandomSource([1]));
    expect(outcome.coinDelta, 0);
    expect(outcome.pendingEffect, PendingEffect.die3);
  });

  test('la especial puede dar cualquiera de los efectos', () {
    var before = 0;
    final numbers = <int>[];
    for (final effect in PendingEffect.values) {
      numbers.add(before + 1);
      before += effect.weight;
    }
    final random = FakeRandomSource(numbers);
    final sorteados = [
      for (var i = 0; i < numbers.length; i++)
        effects.resolve(TileType.special, random).pendingEffect,
    ];
    expect(sorteados, PendingEffect.values);
  });
}
