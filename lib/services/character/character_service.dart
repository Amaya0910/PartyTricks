/// Error al guardar el personaje, con un mensaje para mostrar.
class CharacterException implements Exception {
  const CharacterException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Guarda cómo se ve el personaje del jugador. La versión real usa Cloud
/// Firestore; en las pruebas se puede cambiar por una falsa.
abstract class CharacterService {
  /// Guarda la posición del tono de piel en el perfil. Lanza
  /// [CharacterException] si falla.
  Future<void> setSkinTone({required String uid, required int skinTone});
}
