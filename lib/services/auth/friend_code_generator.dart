import 'dart:math';

/// Genera códigos de amistad de 6 caracteres.
///
/// El alfabeto no incluye letras ni números que se confunden (O/0, I/1), igual
/// que los códigos de sala. La unicidad la garantiza el servicio al guardarlo.
class FriendCodeGenerator {
  FriendCodeGenerator([Random? random]) : _random = random ?? Random.secure();

  static const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int length = 6;

  final Random _random;

  String generate() {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }
}
