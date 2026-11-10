import 'package:party_tricks/models/face_photo.dart';

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

  /// Guarda el número de los ojos equipados. Lanza [CharacterException]
  /// si falla.
  Future<void> setEyes({required String uid, required int eyes});

  /// Guarda la posición del color de ojos. Lanza [CharacterException] si
  /// falla.
  Future<void> setEyeColor({required String uid, required int eyeColor});

  /// Guarda el número de la boca equipada. Lanza [CharacterException] si
  /// falla.
  Future<void> setMouth({required String uid, required int mouth});

  /// Guarda la posición del color de boca. Lanza [CharacterException] si
  /// falla.
  Future<void> setMouthColor({required String uid, required int mouthColor});

  /// Guarda el id de la camisa puesta. Lanza [CharacterException] si falla.
  Future<void> setShirt({required String uid, required int shirt});

  /// Guarda el id del accesorio puesto (0 = ninguno). Lanza
  /// [CharacterException] si falla.
  Future<void> setAccessory({required String uid, required int accessory});

  /// Guarda la posición del color de fondo de la foto de perfil. Lanza
  /// [CharacterException] si falla.
  Future<void> setAvatarColor({required String uid, required int avatarColor});

  /// Guarda la foto de la cara. Con [photo] null, la borra. Lanza
  /// [CharacterException] si falla.
  Future<void> setFacePhoto({required String uid, required FacePhoto? photo});

  /// Guarda si el jugador usa su foto en lugar de los ojos y la boca. Lanza
  /// [CharacterException] si falla.
  Future<void> setUseFacePhoto({required String uid, required bool use});
}
