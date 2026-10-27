import 'package:party_tricks/models/chest.dart';

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
  /// Cobra los diamantes del cofre y entrega el premio. Lanza
  /// [ShopException] si no alcanzan los diamantes o algo falla.
  Future<ChestOutcome> buyChest({
    required String uid,
    required ChestType chest,
  });
}
