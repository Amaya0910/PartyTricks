import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';

/// Accesorios del personaje. En el perfil se guarda solo el [id]; sin
/// accesorio es 0 (en el código, `null`).
///
/// Cada accesorio es un PNG del mismo lienzo que el personaje (512x968) en
/// `assets/images/personaje/accesorios/`, que se dibuja con la cabeza y se
/// mueve con ella. Si de lado se ve distinto, trae otro PNG ([sideFile]); si
/// no, se usa el mismo.
///
/// Todos se compran con monedas en la Tienda. Los precios también están en
/// `firestore.rules` (`accessoryPrice`): si cambian aquí, hay que cambiarlos
/// allá o las compras se rechazarán.
enum AccessoryStyle implements ShopCosmetic {
  ogre(
    1,
    'Orejas de Ogro',
    'Las orejas más famosas del pantano',
    'shrek.png',
    sideFile: 'shrek_lado.png',
    skinTinted: true,
    price: 75,
    rarity: Rarity.epic,
  ),
  jester(
    2,
    'Gorguera de Bufón',
    'Un cuello digno de la corte',
    'buffon.png',
    price: 100,
    rarity: Rarity.legendary,
  );

  const AccessoryStyle(
    this.id,
    this.title,
    this.description,
    this.file, {
    this.sideFile,
    this.skinTinted = false,
    required this.price,
    required this.rarity,
  });

  @override
  final int id;

  @override
  final String title;

  @override
  final String description;

  /// Archivo del dibujo de frente.
  final String file;

  /// Archivo del dibujo de lado, si es distinto.
  final String? sideFile;

  /// Si el relleno del dibujo (blanco) toma el tono de piel del personaje,
  /// como el relleno de la cabeza.
  final bool skinTinted;

  @override
  final int price;

  @override
  final Rarity rarity;

  @override
  CosmeticCategory get category => CosmeticCategory.accessory;

  /// Todos se compran: ninguno viene gratis.
  @override
  bool get isFree => false;

  static const String _folder = 'assets/images/personaje/accesorios';

  String assetFor(CharacterView view) => switch (view) {
    CharacterView.frente => '$_folder/$file',
    CharacterView.lado => '$_folder/${sideFile ?? file}',
    // Por detrás se ven igual que de frente.
    CharacterView.espalda => '$_folder/$file',
  };

  /// Busca el accesorio por su [id]. Null si es 0 (ninguno) o no existe.
  static AccessoryStyle? fromId(int? id) {
    for (final style in values) {
      if (style.id == id) return style;
    }
    return null;
  }
}
