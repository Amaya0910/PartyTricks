import 'dart:math';

/// Crea y revisa los códigos de las salas privadas.
///
/// No usa letras que se confunden, como O y 0 o I y 1.
class RoomCodeGenerator {
  RoomCodeGenerator([Random? random]) : _random = random ?? Random.secure();

  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const length = 6;

  final Random _random;

  String generate() {
    return String.fromCharCodes([
      for (var i = 0; i < length; i++)
        alphabet.codeUnitAt(_random.nextInt(alphabet.length)),
    ]);
  }

  /// Limpia lo que escribe el jugador: quita espacios y pasa a mayúsculas.
  static String normalize(String input) => input.trim().toUpperCase();

  static bool isValid(String code) {
    return code.length == length && code.split('').every(alphabet.contains);
  }
}
