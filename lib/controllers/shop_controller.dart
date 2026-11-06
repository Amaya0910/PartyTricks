import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/shop/shop_providers.dart';
import 'package:party_tricks/services/shop/shop_service.dart';

/// Compra cofres y cosméticos. El estado es true mientras espera respuesta, para mostrar
/// que está cargando.
class ShopController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Devuelve el premio. Lanza [ShopException] con el mensaje a mostrar.
  Future<ChestPrize> buyChest(ChestType chest) {
    return _buy(
      (uid) => ref.read(shopServiceProvider).buyChest(uid: uid, chest: chest),
    );
  }

  /// Compra unos ojos con monedas. Lanza [ShopException] con el mensaje a
  /// mostrar.
  Future<void> buyEyes(EyeStyle eyes) {
    return _buy(
      (uid) => ref.read(shopServiceProvider).buyEyes(uid: uid, eyes: eyes),
    );
  }

  /// Compra una boca con monedas. Lanza [ShopException] con el mensaje a
  /// mostrar.
  Future<void> buyMouth(MouthStyle mouth) {
    return _buy(
      (uid) => ref.read(shopServiceProvider).buyMouth(uid: uid, mouth: mouth),
    );
  }

  Future<T> _buy<T>(Future<T> Function(String uid) purchase) async {
    final uid = ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const ShopException('Inicia sesión para comprar.');
    }
    state = true;
    try {
      return await purchase(uid);
    } finally {
      state = false;
    }
  }
}

final shopControllerProvider = NotifierProvider<ShopController, bool>(
  ShopController.new,
);
