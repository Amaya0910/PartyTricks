import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';

/// Ojos del personaje. En el perfil se guarda solo el [number].
///
/// Cada ojo es un PNG del mismo lienzo que el personaje (512x968) en
/// assets/images/personaje/frente/ojos/. Algunos vienen en dos capas:
/// - `ojo_<n>_relleno.png`: fondo del ojo, no se tiñe.
/// - `ojo_<n>_linea.png`: contorno; sus partes blancas toman el color.
///
/// Otros vienen en un solo PNG (`ojo_<n>.png`), que se tiñe igual que una
/// línea.
///
/// Los de [price] 0 los tienen todos desde el inicio; los demás se compran
/// con monedas en la Tienda. Los precios también están en
/// `firestore.rules` (`eyesPrice`, D-29): si cambian aquí, hay que
/// cambiarlos allá o las compras se rechazarán.
enum EyeStyle implements ShopCosmetic {
  ojo1(
    1,
    'Ojos Pequeñitos',
    'Dos puntitos con brillo travieso',
    price: 30,
    rarity: Rarity.common,
  ),
  ojo2(2, 'Ojos Ilusionados', 'Grandes y con pestañas', layered: true),
  ojo3(
    3,
    'Ojos Burbuja',
    'Redondos como dos burbujas',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  ojo4(
    4,
    'Ojos Somnolientos',
    'Listos para una siesta',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  ojo5(5, 'Ojos Afilados', 'Una mirada intensa', layered: true),
  ojo6(
    6,
    'Ojos Felices',
    'Cerrados de pura alegría',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  ojo7(7, 'Ojos Clásicos', 'Los de siempre'),
  ojo8(
    8,
    'Ojos Aburridos',
    'Mirada de "otra vez lo mismo"',
    price: 60,
    rarity: Rarity.rare,
  ),
  ojo9(
    9,
    'Ojos Curiosos',
    'Siempre mirando hacia arriba',
    price: 60,
    rarity: Rarity.rare,
  ),
  ojo10(
    10,
    'Ojos Despistados',
    'Mirando a otro lado',
    price: 60,
    rarity: Rarity.rare,
  ),
  ojo11(
    11,
    'Ojos Pícaros',
    'Una sonrisa en la mirada',
    layered: true,
    price: 100,
    rarity: Rarity.legendary,
  );

  const EyeStyle(
    this.number,
    this.title,
    this.description, {
    this.layered = false,
    this.price = 0,
    this.rarity = Rarity.common,
  });

  /// Número del archivo y del nombre corto que se ve en el Vestuario
  /// ("Ojo 7").
  final int number;

  /// Nombre y descripción para la Tienda.
  @override
  final String title;
  @override
  final String description;

  /// Si viene en dos capas (línea + relleno).
  final bool layered;

  /// Precio en monedas. 0 si viene gratis con la cuenta.
  @override
  final int price;

  /// Qué tan raro es: define con qué frecuencia sale en los cofres.
  @override
  final Rarity rarity;

  @override
  CosmeticCategory get category => CosmeticCategory.eyes;

  @override
  int get id => number;

  /// Si lo tienen todos desde el inicio.
  @override
  bool get isFree => price == 0;

  /// Ojos de quien todavía no ha elegido unos.
  static const EyeStyle defaultStyle = ojo7;

  static String _folder(CharacterView view) =>
      'assets/images/personaje/${view.folder}/ojos';

  /// Capa que se tiñe con el color de ojos.
  String get tintedAsset => tintedAssetIn(CharacterView.frente);

  /// Capa de abajo, sin teñir. Null si el ojo es un solo PNG.
  String? get fillAsset => fillAssetIn(CharacterView.frente);

  /// Lo mismo, vistos desde [view] (de frente o de lado).
  String tintedAssetIn(CharacterView view) => layered
      ? '${_folder(view)}/ojo_${number}_linea.png'
      : '${_folder(view)}/ojo_$number.png';

  String? fillAssetIn(CharacterView view) =>
      layered ? '${_folder(view)}/ojo_${number}_relleno.png' : null;

  /// Busca el ojo por número (por si en Firestore queda un valor viejo o
  /// que ya no existe, devuelve [defaultStyle]).
  static EyeStyle fromNumber(int? number) {
    for (final style in values) {
      if (style.number == number) return style;
    }
    return defaultStyle;
  }
}
