import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/models/rarity.dart';

/// Un cosmético que se compra en la Tienda y sale en los cofres: ojos, boca,
/// camisa o accesorio. Lo que tienen en común, para tratarlos igual en la
/// Tienda, los cofres y las compras.
abstract interface class ShopCosmetic {
  /// La pestaña del Vestuario donde se pone.
  CosmeticCategory get category;

  /// Número con el que se guarda en el perfil (`ownedEyes`, `ownedShirts`...).
  /// Dentro de una categoría no se repite.
  int get id;

  String get title;
  String get description;

  /// Precio en monedas. 0 si viene gratis con la cuenta.
  int get price;

  /// Qué tan raro es: define con qué frecuencia sale en los cofres.
  Rarity get rarity;

  /// Si lo tienen todos desde el inicio.
  bool get isFree;
}
