import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// Camisa puesta. Se lee del perfil en vivo, así que al guardarla se
/// actualiza sola en el Vestuario y en la pantalla principal.
final shirtProvider = Provider<ShirtStyle>(
  (ref) =>
      ref.watch(userProfileProvider).value?.shirt ?? ShirtStyle.defaultStyle,
);

/// Camisas que puede ponerse el jugador: la de inicio y las que compró.
final ownedShirtsProvider = Provider<List<ShirtStyle>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return [
    for (final style in ShirtStyle.values)
      if (profile?.ownsShirt(style) ?? style.isFree) style,
  ];
});

/// Camisas que todavía no tiene: las que se ven en la Tienda.
final shirtsForSaleProvider = Provider<List<ShirtStyle>>((ref) {
  final owned = ref.watch(ownedShirtsProvider);
  return [
    for (final style in ShirtStyle.values)
      if (!owned.contains(style)) style,
  ];
});

/// Cambia la camisa desde el Vestuario.
class ShirtController {
  ShirtController(this._ref);

  final Ref _ref;

  /// Lanza [CharacterException] con el mensaje a mostrar.
  Future<void> select(ShirtStyle style) async {
    if (style == _ref.read(shirtProvider)) return;
    if (!_ref.read(ownedShirtsProvider).contains(style)) {
      throw const CharacterException('Compra esta camisa en la Tienda.');
    }
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const CharacterException('Inicia sesión para cambiar tu camisa.');
    }
    await _ref
        .read(characterServiceProvider)
        .setShirt(uid: uid, shirt: style.id);
  }
}

final shirtControllerProvider = Provider<ShirtController>(ShirtController.new);
