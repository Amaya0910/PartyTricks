import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// Pantalón puesto, o null si no lleva ninguno. Se lee del perfil en vivo.
final pantsProvider = Provider<PantsStyle?>(
  (ref) => ref.watch(userProfileProvider).value?.pants,
);

/// Pantalones que puede ponerse el jugador: los que compró.
final ownedPantsProvider = Provider<List<PantsStyle>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return [
    for (final style in PantsStyle.values)
      if (profile?.ownsPants(style) ?? style.isFree) style,
  ];
});

/// Pantalones que todavía no tiene: los que se ven en la Tienda.
final pantsForSaleProvider = Provider<List<PantsStyle>>((ref) {
  final owned = ref.watch(ownedPantsProvider);
  return [
    for (final style in PantsStyle.values)
      if (!owned.contains(style)) style,
  ];
});

/// Cambia el pantalón desde el Vestuario.
class PantsController {
  PantsController(this._ref);

  final Ref _ref;

  /// Pone [style], o se lo quita si es null. Lanza [CharacterException] con
  /// el mensaje a mostrar.
  Future<void> select(PantsStyle? style) async {
    if (style == _ref.read(pantsProvider)) return;
    if (style != null && !_ref.read(ownedPantsProvider).contains(style)) {
      throw const CharacterException('Compra este pantalón en la Tienda.');
    }
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const CharacterException('Inicia sesión para cambiar tu pantalón.');
    }
    await _ref
        .read(characterServiceProvider)
        .setPants(uid: uid, pants: style?.id ?? 0);
  }
}

final pantsControllerProvider = Provider<PantsController>(PantsController.new);
