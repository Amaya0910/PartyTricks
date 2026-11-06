import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// Boca equipada. Se lee del perfil en vivo, así que al guardarla se
/// actualiza sola en el Vestuario y en la pantalla principal.
final mouthStyleProvider = Provider<MouthStyle>(
  (ref) =>
      ref.watch(userProfileProvider).value?.mouth ?? MouthStyle.defaultStyle,
);

/// Bocas que puede ponerse el jugador: las gratis y las que compró.
final ownedMouthsProvider = Provider<List<MouthStyle>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return [
    for (final style in MouthStyle.values)
      if (profile?.ownsMouth(style) ?? style.isFree) style,
  ];
});

/// Bocas que todavía no tiene: las que se ven en la Tienda.
final mouthsForSaleProvider = Provider<List<MouthStyle>>((ref) {
  final owned = ref.watch(ownedMouthsProvider);
  return [
    for (final style in MouthStyle.values)
      if (!owned.contains(style)) style,
  ];
});

/// Posición del color de boca elegido (ver MouthColor).
final mouthColorProvider = Provider<int>(
  (ref) =>
      ref.watch(userProfileProvider).value?.mouthColor ??
      MouthColor.defaultIndex,
);

/// Cambia la boca y su color desde el Vestuario.
class MouthController {
  MouthController(this._ref);

  final Ref _ref;

  /// Lanza [CharacterException] con el mensaje a mostrar.
  Future<void> selectStyle(MouthStyle style) async {
    if (style == _ref.read(mouthStyleProvider)) return;
    if (!_ref.read(ownedMouthsProvider).contains(style)) {
      throw const CharacterException('Compra esta boca en la Tienda.');
    }
    await _ref
        .read(characterServiceProvider)
        .setMouth(uid: _uid(), mouth: style.number);
  }

  /// Lanza [CharacterException] con el mensaje a mostrar.
  Future<void> selectColor(int index) async {
    final mouthColor = MouthColor.clamp(index);
    if (mouthColor == _ref.read(mouthColorProvider)) return;
    await _ref
        .read(characterServiceProvider)
        .setMouthColor(uid: _uid(), mouthColor: mouthColor);
  }

  String _uid() {
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const CharacterException('Inicia sesión para cambiar tu boca.');
    }
    return uid;
  }
}

final mouthControllerProvider = Provider<MouthController>(MouthController.new);
