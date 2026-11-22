import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/shirt_style.dart';

/// Error al comprar, con un mensaje para mostrar.
class ShopException implements Exception {
  const ShopException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Compras de la tienda. La versión real usa Cloud Firestore; en las
/// pruebas se puede cambiar por una falsa.
abstract class ShopService {
  /// Cobra los diamantes del cofre y entrega el premio (si sale un
  /// cosmético, ya queda guardado en el perfil). Lanza [ShopException] si no
  /// alcanzan los diamantes o algo falla.
  Future<ChestPrize> buyChest({required String uid, required ChestType chest});

  /// Cobra las monedas de [eyes] y los agrega a los ojos del jugador. Lanza
  /// [ShopException] si ya los tiene, si son gratis, si no alcanzan las
  /// monedas o si algo falla.
  Future<void> buyEyes({required String uid, required EyeStyle eyes});

  /// Cobra las monedas de [mouth] y la agrega a las bocas del jugador.
  /// Lanza [ShopException] si ya la tiene, si es gratis, si no alcanzan las
  /// monedas o si algo falla.
  Future<void> buyMouth({required String uid, required MouthStyle mouth});

  /// Cobra las monedas de [shirt] y la agrega a las camisas del jugador.
  /// Lanza [ShopException] si ya la tiene, si es gratis, si no alcanzan las
  /// monedas o si algo falla.
  Future<void> buyShirt({required String uid, required ShirtStyle shirt});

  /// Cobra las monedas de [accessory] y lo agrega a los accesorios del
  /// jugador. Lanza [ShopException] si ya lo tiene, si no alcanzan las
  /// monedas o si algo falla.
  Future<void> buyAccessory({
    required String uid,
    required AccessoryStyle accessory,
  });

  /// Cobra las monedas de [pants] y lo agrega a los pantalones del jugador.
  /// Lanza [ShopException] si ya lo tiene, si no alcanzan las monedas o si
  /// algo falla.
  Future<void> buyPants({required String uid, required PantsStyle pants});

  /// Cobra las monedas de [hair] y lo agrega a los cabellos del jugador.
  /// Lanza [ShopException] si ya lo tiene, si no alcanzan las monedas o si
  /// algo falla.
  Future<void> buyHair({required String uid, required HairStyle hair});
}
