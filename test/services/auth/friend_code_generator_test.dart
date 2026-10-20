import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/auth/friend_code_generator.dart';

void main() {
  test('genera códigos de 6 caracteres del alfabeto permitido', () {
    final generator = FriendCodeGenerator(Random(42));

    for (var i = 0; i < 200; i++) {
      final code = generator.generate();
      expect(code.length, FriendCodeGenerator.length);
      for (final char in code.split('')) {
        expect(FriendCodeGenerator.alphabet.contains(char), isTrue);
      }
    }
  });

  test('el alfabeto no tiene caracteres que se confunden', () {
    for (final char in ['O', '0', 'I', '1']) {
      expect(FriendCodeGenerator.alphabet.contains(char), isFalse);
    }
  });

  test('con la misma semilla genera el mismo código', () {
    final first = FriendCodeGenerator(Random(7)).generate();
    final second = FriendCodeGenerator(Random(7)).generate();

    expect(first, second);
  });
}
