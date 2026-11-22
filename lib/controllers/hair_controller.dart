import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/hair_color.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// Cabello puesto, o null si no lleva ninguno. Se lee del perfil en vivo.
final hairProvider = Provider<HairStyle?>(
  (ref) => ref.watch(userProfileProvider).value?.hair,
);

/// Posición del color del cabello elegido (ver HairColor).
final hairColorProvider = Provider<int>(
  (ref) =>
      ref.watch(userProfileProvider).value?.hairColor ?? HairColor.defaultIndex,
);

/// Cabellos que puede ponerse el jugador: los que compró.
final ownedHairsProvider = Provider<List<HairStyle>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return [
    for (final style in HairStyle.values)
      if (profile?.ownsHair(style) ?? style.isFree) style,
  ];
});

/// Cabellos que todavía no tiene: los que se ven en la Tienda.
final hairsForSaleProvider = Provider<List<HairStyle>>((ref) {
  final owned = ref.watch(ownedHairsProvider);
  return [
    for (final style in HairStyle.values)
      if (!owned.contains(style)) style,
  ];
});

/// Cambia el cabello y su color desde el Vestuario.
class HairController {
  HairController(this._ref);

  final Ref _ref;

  String _uid() {
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const CharacterException('Inicia sesión para cambiar tu cabello.');
    }
    return uid;
  }

  /// Pone [style], o se lo quita si es null. Lanza [CharacterException] con
  /// el mensaje a mostrar.
  Future<void> select(HairStyle? style) async {
    if (style == _ref.read(hairProvider)) return;
    if (style != null && !_ref.read(ownedHairsProvider).contains(style)) {
      throw const CharacterException('Compra este cabello en la Tienda.');
    }
    await _ref
        .read(characterServiceProvider)
        .setHair(uid: _uid(), hair: style?.id ?? 0);
  }

  /// Cambia el color de los cabellos blancos. Lanza [CharacterException] con
  /// el mensaje a mostrar.
  Future<void> selectColor(int index) async {
    final hairColor = HairColor.clamp(index);
    if (hairColor == _ref.read(hairColorProvider)) return;
    await _ref
        .read(characterServiceProvider)
        .setHairColor(uid: _uid(), hairColor: hairColor);
  }
}

final hairControllerProvider = Provider<HairController>(HairController.new);
