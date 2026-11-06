import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// Ojos equipados. Se leen del perfil en vivo, así que al guardarlos se
/// actualizan solos en el Vestuario y en la pantalla principal.
final eyeStyleProvider = Provider<EyeStyle>(
  (ref) => ref.watch(userProfileProvider).value?.eyes ?? EyeStyle.defaultStyle,
);

/// Ojos que puede ponerse el jugador: los gratis y los que compró.
final ownedEyesProvider = Provider<List<EyeStyle>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return [
    for (final style in EyeStyle.values)
      if (profile?.ownsEyes(style) ?? style.isFree) style,
  ];
});

/// Ojos que todavía no tiene: los que se ven en la Tienda.
final eyesForSaleProvider = Provider<List<EyeStyle>>((ref) {
  final owned = ref.watch(ownedEyesProvider);
  return [
    for (final style in EyeStyle.values)
      if (!owned.contains(style)) style,
  ];
});

/// Posición del color de ojos elegido (ver EyeColor).
final eyeColorProvider = Provider<int>(
  (ref) =>
      ref.watch(userProfileProvider).value?.eyeColor ?? EyeColor.defaultIndex,
);

/// Cambia los ojos y su color desde el Vestuario.
class EyesController {
  EyesController(this._ref);

  final Ref _ref;

  /// Lanza [CharacterException] con el mensaje a mostrar.
  Future<void> selectStyle(EyeStyle style) async {
    if (style == _ref.read(eyeStyleProvider)) return;
    if (!_ref.read(ownedEyesProvider).contains(style)) {
      throw const CharacterException('Compra estos ojos en la Tienda.');
    }
    await _ref
        .read(characterServiceProvider)
        .setEyes(uid: _uid(), eyes: style.number);
  }

  /// Lanza [CharacterException] con el mensaje a mostrar.
  Future<void> selectColor(int index) async {
    final eyeColor = EyeColor.clamp(index);
    if (eyeColor == _ref.read(eyeColorProvider)) return;
    await _ref
        .read(characterServiceProvider)
        .setEyeColor(uid: _uid(), eyeColor: eyeColor);
  }

  String _uid() {
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const CharacterException('Inicia sesión para cambiar tus ojos.');
    }
    return uid;
  }
}

final eyesControllerProvider = Provider<EyesController>(EyesController.new);
