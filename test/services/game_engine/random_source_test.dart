import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';

void main() {
  test('el dado de 6 siempre cae entre 1 y 6', () {
    final random = DartRandomSource(Random(42));
    for (var i = 0; i < 1000; i++) {
      expect(random.rollDie(), inInclusiveRange(1, 6));
    }
  });

  test('el dado de 12 puede llegar a 12', () {
    final random = DartRandomSource(Random(7));
    final valores = {for (var i = 0; i < 2000; i++) random.rollDie(12)};
    expect(valores, containsAll([1, 12]));
  });
}
