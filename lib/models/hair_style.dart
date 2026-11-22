import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';

/// Cabellos del personaje. En el perfil se guarda solo el [id]; sin cabello
/// es 0 (en el código, `null`).
///
/// Cada cabello es un PNG del mismo lienzo que el personaje (512x968) en
/// `assets/images/personaje/<vista>/cabellos/cabello_<id>.png`. Algunos traen
/// además una parte de atrás (`cabello_<id>_atras.png`) que se dibuja detrás
/// de la cabeza.
///
/// Los cabellos blancos ([tintable]) toman el color que elija el jugador
/// (`HairColor`); los demás traen su propio color. Todos los colores están
/// desbloqueados: no se compran.
///
/// Todos se compran con monedas en la Tienda. Los precios también están en
/// `firestore.rules` (`hairPrice`): si cambian aquí, hay que cambiarlos allá
/// o las compras se rechazarán.
enum HairStyle implements ShopCosmetic {
  tufts(
    1,
    'Mechones Azules',
    'Frescos y un poco revueltos',
    hasBackInFront: true,
    price: 45,
    rarity: Rarity.uncommon,
  ),
  clouds(
    2,
    'Nube de Rizos',
    'Esponjoso como una nube',
    tintable: true,
    price: 60,
    rarity: Rarity.rare,
  ),
  pigtails(
    3,
    'Coletas Doradas',
    'Dos coletas con mucha energía',
    hasBackInFront: true,
    price: 60,
    rarity: Rarity.rare,
  ),
  wild(
    4,
    'Greñas Verdes',
    'Salvajes y llenas de carácter',
    price: 75,
    rarity: Rarity.epic,
  ),
  bun(
    5,
    'Peinado Castaño',
    'Pulcro y bien peinado',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  mane(
    6,
    'Melena Larga',
    'Largo, suave y con flequillo',
    tintable: true,
    hasBackInFront: true,
    price: 60,
    rarity: Rarity.rare,
  ),
  spikes(
    7,
    'Puntas al Cielo',
    'Apunta hacia las estrellas',
    tintable: true,
    price: 75,
    rarity: Rarity.epic,
  ),
  midnight(
    8,
    'Pinchos de Medianoche',
    'Oscuros y afilados',
    price: 75,
    rarity: Rarity.epic,
  ),
  fringe(
    9,
    'Flequillo Recto',
    'Corte limpio y derecho',
    tintable: true,
    price: 45,
    rarity: Rarity.uncommon,
  ),
  curl(
    10,
    'Rizo de Medianoche',
    'Un solo rizo con mucho estilo',
    price: 60,
    rarity: Rarity.rare,
  ),
  clownWig(
    11,
    'Peluca de Payaso',
    'Todos los colores del circo',
    price: 300,
    rarity: Rarity.legendary,
  );

  const HairStyle(
    this.id,
    this.title,
    this.description, {
    this.tintable = false,
    this.hasBackInFront = false,
    required this.price,
    required this.rarity,
  });

  @override
  final int id;

  @override
  final String title;

  @override
  final String description;

  /// Si es blanco y toma el color que elija el jugador.
  final bool tintable;

  /// Si de frente tiene una parte que va detrás de la cabeza. De lado, el
  /// dibujo es uno solo.
  final bool hasBackInFront;

  @override
  final int price;

  @override
  final Rarity rarity;

  @override
  CosmeticCategory get category => CosmeticCategory.hair;

  /// Todos se compran: ninguno viene gratis.
  @override
  bool get isFree => false;

  static String _path(CharacterView view, String file) =>
      'assets/images/personaje/${view.folder}/cabellos/$file';

  /// El dibujo que va delante de la cabeza. De espalda cubre la parte de
  /// atrás de la cabeza (`espalda/cabellos/`).
  String assetFor(CharacterView view) => _path(view, 'cabello_$id.png');

  /// La parte que va detrás de la cabeza, o null si este cabello no la tiene
  /// en esa vista.
  String? backAssetFor(CharacterView view) =>
      view == CharacterView.frente && hasBackInFront
      ? _path(view, 'cabello_${id}_atras.png')
      : null;

  /// Busca el cabello por su [id]. Null si es 0 (ninguno) o no existe.
  static HairStyle? fromId(int? id) {
    for (final style in values) {
      if (style.id == id) return style;
    }
    return null;
  }
}
