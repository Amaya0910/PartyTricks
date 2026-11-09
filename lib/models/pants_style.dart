import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';

/// Pantalones del personaje. En el perfil se guarda solo el [id]; sin
/// pantalón es 0 (en el código, `null`).
///
/// Cada pantalón es un PNG del mismo lienzo que el personaje (512x968) en
/// `assets/images/personaje/frente/pantalones/pantalon_<id>.png`. Por ahora
/// solo hay dibujo de frente: de lado (caminando) todavía no se ve.
///
/// Todos se compran con monedas en la Tienda. Los precios también están en
/// `firestore.rules` (`pantsPrice`): si cambian aquí, hay que cambiarlos allá
/// o las compras se rechazarán.
enum PantsStyle implements ShopCosmetic {
  golden(
    1,
    'Pantalón Dorado',
    'Brilla desde la cadera',
    price: 45,
    rarity: Rarity.uncommon,
  );

  const PantsStyle(
    this.id,
    this.title,
    this.description, {
    required this.price,
    required this.rarity,
  });

  @override
  final int id;

  @override
  final String title;

  @override
  final String description;

  @override
  final int price;

  @override
  final Rarity rarity;

  @override
  CosmeticCategory get category => CosmeticCategory.pants;

  /// Todos se compran: ninguno viene gratis.
  @override
  bool get isFree => false;

  /// El dibujo de [view], o null si ese pantalón todavía no lo tiene.
  String? assetFor(CharacterView view) => view == CharacterView.frente
      ? 'assets/images/personaje/frente/pantalones/pantalon_$id.png'
      : null;

  /// Busca el pantalón por su [id]. Null si es 0 (ninguno) o no existe.
  static PantsStyle? fromId(int? id) {
    for (final style in values) {
      if (style.id == id) return style;
    }
    return null;
  }
}
