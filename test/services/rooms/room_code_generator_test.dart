import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/rooms/room_code_generator.dart';

void main() {
  test('crea códigos de 6 caracteres válidos', () {
    final generator = RoomCodeGenerator(Random(1));
    for (var i = 0; i < 100; i++) {
      expect(RoomCodeGenerator.isValid(generator.generate()), isTrue);
    }
  });

  test('limpia lo que escribe el jugador', () {
    expect(RoomCodeGenerator.normalize('  abc234 '), 'ABC234');
  });

  test('rechaza códigos mal escritos', () {
    expect(RoomCodeGenerator.isValid('ABC23'), isFalse);
    expect(RoomCodeGenerator.isValid('ABC2340'), isFalse);
    expect(RoomCodeGenerator.isValid('ABCO12'), isFalse);
  });
}
