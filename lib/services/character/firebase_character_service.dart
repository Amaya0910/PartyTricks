import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// El tono de piel vive en el perfil (`users/{uid}`, campo `skinTone`).
class FirebaseCharacterService implements CharacterService {
  FirebaseCharacterService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> setSkinTone({
    required String uid,
    required int skinTone,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'skinTone': skinTone,
      });
    } on FirebaseException catch (e) {
      debugPrint('Tono de piel: ${e.code} ${e.message}');
      throw const CharacterException(
        'No se pudo guardar el tono. Revisa tu conexión.',
      );
    }
  }
}
