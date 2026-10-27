import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/shop/shop_providers.dart';
import 'package:party_tricks/services/shop/shop_service.dart';

/// Compra cofres. El estado es true mientras espera respuesta, para mostrar
/// que está cargando.
class ShopController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Devuelve el premio. Lanza [ShopException] con el mensaje a mostrar.
  Future<ChestOutcome> buyChest(ChestType chest) async {
    final uid = ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const ShopException('Inicia sesión para comprar.');
    }
    state = true;
    try {
      return await ref
          .read(shopServiceProvider)
          .buyChest(uid: uid, chest: chest);
    } finally {
      state = false;
    }
  }
}

final shopControllerProvider = NotifierProvider<ShopController, bool>(
  ShopController.new,
);