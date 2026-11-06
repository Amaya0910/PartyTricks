import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// El aspecto del personaje vive en el perfil (`users/{uid}`): campos
/// `skinTone`, `eyes`, `eyeColor`, `mouth` y `mouthColor`.
class FirebaseCharacterService implements CharacterService {
  FirebaseCharacterService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> setSkinTone({required String uid, required int skinTone}) =>
      _update(uid, 'skinTone', skinTone, 'No se pudo guardar el tono.');

  @override
  Future<void> setEyes({required String uid, required int eyes}) =>
      _update(uid, 'eyes', eyes, 'No se pudieron guardar los ojos.');

  @override
  Future<void> setEyeColor({required String uid, required int eyeColor}) =>
      _update(uid, 'eyeColor', eyeColor, 'No se pudo guardar el color.');

  @override
  Future<void> setMouth({required String uid, required int mouth}) =>
      _update(uid, 'mouth', mouth, 'No se pudo guardar la boca.');

  @override
  Future<void> setMouthColor({required String uid, required int mouthColor}) =>
      _update(uid, 'mouthColor', mouthColor, 'No se pudo guardar el color.');

  @override
  Future<void> setAvatarColor({
    required String uid,
    required int avatarColor,
  }) =>
      _update(uid, 'avatarColor', avatarColor, 'No se pudo guardar el color.');

  @override
  Future<void> setFacePhoto({required String uid, required FacePhoto? photo}) =>
      _update(
        uid,
        'facePhoto',
        photo?.base64 ?? FieldValue.delete(),
        'No se pudo guardar la foto.',
      );

  @override
  Future<void> setUseFacePhoto({required String uid, required bool use}) =>
      _update(uid, 'useFacePhoto', use, 'No se pudo guardar el cambio.');

  Future<void> _update(
    String uid,
    String field,
    Object value,
    String failMessage,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update({field: value});
    } on FirebaseException catch (e) {
      debugPrint('Personaje ($field): ${e.code} ${e.message}');
      throw CharacterException('$failMessage Revisa tu conexión.');
    }
  }
}
