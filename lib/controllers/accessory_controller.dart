import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// Accesorio puesto, o null si no lleva ninguno. Se lee del perfil en vivo.
final accessoryProvider = Provider<AccessoryStyle?>(
  (ref) => ref.watch(userProfileProvider).value?.accessory,
);

/// Accesorios que puede ponerse el jugador: los que compró.
final ownedAccessoriesProvider = Provider<List<AccessoryStyle>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return [
    for (final style in AccessoryStyle.values)
      if (profile?.ownsAccessory(style) ?? style.isFree) style,
  ];
});

/// Accesorios que todavía no tiene: los que se ven en la Tienda.
final accessoriesForSaleProvider = Provider<List<AccessoryStyle>>((ref) {
  final owned = ref.watch(ownedAccessoriesProvider);
  return [
    for (final style in AccessoryStyle.values)
      if (!owned.contains(style)) style,
  ];
});

/// Cambia el accesorio desde el Vestuario.
class AccessoryController {
  AccessoryController(this._ref);

  final Ref _ref;

  /// Pone [style], o se lo quita si es null. Lanza [CharacterException] con
  /// el mensaje a mostrar.
  Future<void> select(AccessoryStyle? style) async {
    if (style == _ref.read(accessoryProvider)) return;
    if (style != null && !_ref.read(ownedAccessoriesProvider).contains(style)) {
      throw const CharacterException('Compra este accesorio en la Tienda.');
    }
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const CharacterException(
        'Inicia sesión para cambiar tu accesorio.',
      );
    }
    await _ref
        .read(characterServiceProvider)
        .setAccessory(uid: uid, accessory: style?.id ?? 0);
  }
}

final accessoryControllerProvider = Provider<AccessoryController>(
  AccessoryController.new,
);
