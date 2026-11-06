import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// Tono de piel del jugador. Se lee del perfil en vivo, así que al
/// guardarlo se actualiza solo en el Vestuario y en la pantalla principal.
final skinToneProvider = Provider<int>(
  (ref) =>
      ref.watch(userProfileProvider).value?.skinTone ?? SkinTone.defaultIndex,
);

/// Cambia el tono de piel desde el Vestuario.
class SkinToneController {
  SkinToneController(this._ref);

  final Ref _ref;

  /// Lanza [CharacterException] con el mensaje a mostrar.
  Future<void> select(int index) async {
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const CharacterException('Inicia sesión para cambiar tu tono.');
    }
    final skinTone = SkinTone.clamp(index);
    if (skinTone == _ref.read(skinToneProvider)) return;
    await _ref
        .read(characterServiceProvider)
        .setSkinTone(uid: uid, skinTone: skinTone);
  }
}

final skinToneControllerProvider = Provider<SkinToneController>(
  SkinToneController.new,
);
