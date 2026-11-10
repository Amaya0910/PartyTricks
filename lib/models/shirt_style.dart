import 'package:flutter/material.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';

/// Camisas del personaje. En el perfil se guarda solo el [id].
///
/// Cada camisa es un PNG del mismo lienzo que el personaje (512x768) más sus
/// mangas, que giran con los brazos:
/// - de frente (`frente/camisas/`): `camisa_<n>.png` y
///   `manga_<n>_izquierda.png` / `manga_<n>_derecha.png`;
/// - de lado (`lado/camisas/`): `camisa_<n>.png` y una sola `manga_<n>.png`
///   para los dos brazos. Si la camisa no se ve igual yendo a la derecha que
///   a la izquierda ([sidedInProfile]), trae `camisa_<n>_derecha.png` y
///   `camisa_<n>_izquierda.png`.
///
/// La camisa 1 es blanca y toma color ([tint]): es la camisa de inicio (azul)
/// y tiene otros 8 colores en la Tienda. Las demás se dibujan como están.
///
/// Los de [price] 0 los tienen todos desde el inicio; los demás se compran
/// con monedas en la Tienda. Los precios también están en
/// `firestore.rules` (`shirtPrice`): si cambian aquí, hay que cambiarlos
/// allá o las compras se rechazarán.
enum ShirtStyle implements ShopCosmetic {
  // --- La camisa 1 en sus 9 colores. ---
  blue(
    1,
    1,
    'Camisa Básica Azul',
    'La camisa de siempre',
    tint: Color(0xFF2F6FDE),
  ),
  red(
    101,
    1,
    'Camisa Básica Roja',
    'La de siempre, en rojo',
    tint: Color(0xFFE03C3C),
    price: 30,
  ),
  green(
    102,
    1,
    'Camisa Básica Verde',
    'La de siempre, en verde',
    tint: Color(0xFF3FA34D),
    price: 30,
  ),
  yellow(
    103,
    1,
    'Camisa Básica Amarilla',
    'La de siempre, en amarillo',
    tint: Color(0xFFF2C230),
    price: 30,
  ),
  orange(
    104,
    1,
    'Camisa Básica Naranja',
    'La de siempre, en naranja',
    tint: Color(0xFFF28A2E),
    price: 30,
  ),
  purple(
    105,
    1,
    'Camisa Básica Morada',
    'La de siempre, en morado',
    tint: Color(0xFF8E4FD1),
    price: 30,
  ),
  pink(
    106,
    1,
    'Camisa Básica Rosa',
    'La de siempre, en rosa',
    tint: Color(0xFFF271A8),
    price: 30,
  ),
  teal(
    107,
    1,
    'Camisa Básica Turquesa',
    'La de siempre, en turquesa',
    tint: Color(0xFF25B5B0),
    price: 30,
  ),
  black(
    108,
    1,
    'Camisa Básica Negra',
    'La de siempre, en negro',
    tint: Color(0xFF2B2B2B),
    price: 30,
  ),

  // --- Las demás camisas, con su arte propio. ---
  stripe(
    2,
    2,
    'Camiseta Franja',
    'Una franja negra en el pecho',
    hasSleeves: false,
    price: 45,
    rarity: Rarity.uncommon,
  ),
  greenSoccer(
    3,
    3,
    'Camiseta Verdiblanca',
    'Rayas verdes de equipo de fútbol',
    price: 60,
    rarity: Rarity.rare,
  ),
  redSoccer(
    4,
    4,
    'Camiseta Rojiblanca',
    'Rayas rojas de equipo de fútbol',
    price: 60,
    rarity: Rarity.rare,
  ),
  clown(
    5,
    5,
    'Traje de Payaso',
    'Para hacer reír a toda la fiesta',
    sidedInProfile: true,
    price: 75,
    rarity: Rarity.epic,
  ),
  shifts1(
    6,
    6,
    "Camiseta Shift's 1",
    "Primer drop de Shift's",
    price: 45,
    rarity: Rarity.uncommon,
  ),
  shifts2(
    7,
    7,
    "Camiseta Shift's 2",
    "Primer drop de Shift's",
    price: 45,
    rarity: Rarity.uncommon,
  ),
  shifts3(
    8,
    8,
    "Camiseta Shift's 3",
    "Primer drop de Shift's",
    price: 60,
    rarity: Rarity.rare,
  ),
  shifts4(
    9,
    9,
    "Camiseta Shift's 4",
    "Primer drop de Shift's",
    price: 60,
    rarity: Rarity.rare,
  ),
  shifts5(
    10,
    10,
    "Camiseta Shift's 5",
    "Primer drop de Shift's",
    price: 75,
    rarity: Rarity.epic,
  ),
  shifts6(
    11,
    11,
    "Camiseta Shift's 6",
    "Primer drop de Shift's",
    price: 75,
    rarity: Rarity.epic,
  ),
  shifts7(
    12,
    12,
    "Camiseta Shift's 7",
    "Primer drop de Shift's",
    price: 100,
    rarity: Rarity.legendary,
  );

  const ShirtStyle(
    this.id,
    this.art,
    this.title,
    this.description, {
    this.tint,
    this.hasSleeves = true,
    this.sidedInProfile = false,
    this.price = 0,
    this.rarity = Rarity.common,
  });

  /// Número con el que se guarda en el perfil. La camisa 1 azul es el 1 y sus
  /// otros colores van del 101 al 108; las demás, su mismo número.
  @override
  final int id;

  /// Número del arte (`camisa_<art>.png`).
  final int art;

  @override
  final String title;

  @override
  final String description;

  /// Color que toma el dibujo (es blanco). Null: se dibuja como está.
  final Color? tint;

  /// Si tiene mangas (la camisa 2 no).
  final bool hasSleeves;

  /// Si de lado se ve distinta yendo a la derecha que a la izquierda.
  final bool sidedInProfile;

  @override
  final int price;

  @override
  final Rarity rarity;

  @override
  CosmeticCategory get category => CosmeticCategory.shirt;

  @override
  bool get isFree => price == 0;

  /// Camisa de quien todavía no ha elegido una.
  static const ShirtStyle defaultStyle = blue;

  static const String _root = 'assets/images/personaje';

  /// La camisa vista desde [view]. [faceRight] solo importa de lado, en las
  /// camisas que se ven distinto según hacia dónde van.
  String bodyAsset(CharacterView view, {bool faceRight = true}) {
    switch (view) {
      case CharacterView.frente:
        return '$_root/frente/camisas/camisa_$art.png';
      case CharacterView.lado:
        return sidedInProfile
            ? '$_root/lado/camisas/camisa_${art}_${faceRight ? 'derecha' : 'izquierda'}.png'
            : '$_root/lado/camisas/camisa_$art.png';
    }
  }

  /// Manga de frente: la del brazo izquierdo o la del derecho (como se ven
  /// en la pantalla). Null si la camisa no tiene mangas.
  String? frontSleeve({required bool left}) => hasSleeves
      ? '$_root/frente/camisas/manga_${art}_${left ? 'izquierda' : 'derecha'}.png'
      : null;

  /// Manga de lado (la misma para los dos brazos). Null si no tiene.
  String? get sideSleeve =>
      hasSleeves ? '$_root/lado/camisas/manga_$art.png' : null;

  /// Busca la camisa por su [id] (por si en Firestore queda un valor viejo o
  /// que ya no existe, devuelve [defaultStyle]).
  static ShirtStyle fromId(int? id) {
    for (final style in values) {
      if (style.id == id) return style;
    }
    return defaultStyle;
  }
}
