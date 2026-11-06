import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/avatar_color.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// Posición del color de fondo de la foto de perfil (ver AvatarColor).
final avatarColorProvider = Provider<int>(
  (ref) =>
      ref.watch(userProfileProvider).value?.avatarColor ??
      AvatarColor.defaultIndex,
);

/// Cambia el color de fondo de la foto de perfil desde Ajustes.
class AvatarController {
  AvatarController(this._ref);

  final Ref _ref;

  /// Lanza [CharacterException] con el mensaje a mostrar.
  Future<void> selectColor(int index) async {
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const CharacterException('Inicia sesión para cambiar el color.');
    }
    final avatarColor = AvatarColor.clamp(index);
    if (avatarColor == _ref.read(avatarColorProvider)) return;
    await _ref
        .read(characterServiceProvider)
        .setAvatarColor(uid: uid, avatarColor: avatarColor);
  }
}

final avatarControllerProvider = Provider<AvatarController>(
  AvatarController.new,
);
