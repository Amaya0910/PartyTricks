import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';

/// Qué tanto cubre el pantalón. Decide cuántas capas tiene de lado.
enum PantsCut {
  /// Hasta el tobillo: cadera, muslo y rodilla (gira con la pierna).
  long,

  /// Hasta la rodilla: cadera y muslo.
  short,

  /// Falda: solo una pieza en la cadera, que no se mueve y va sobre las
  /// piernas.
  skirt,
}

/// Pantalones del personaje. En el perfil se guarda solo el [id]; sin
/// pantalón es 0 (en el código, `null`).
///
/// **Dibujo de frente:** un PNG del mismo lienzo que el personaje (512x968)
/// en `assets/images/personaje/frente/pantalones/pantalon_<id>.png`. Va sobre
/// las dos piernas y debajo de los brazos.
///
/// **Dibujo de lado** (la caminata y el reposo de lado), en
/// `assets/images/personaje/lado/pantalones/`, también de 512x968:
///   - `pantalon_<id>_cadera.png`: la cintura y la cadera (no se mueven).
///   - `pantalon_<id>_muslo.png`: sobre el muslo del personaje (gira con él).
///   - `pantalon_<id>_rodilla.png`: sobre la pantorrilla (gira con ella).
/// Según el [cut] faltan algunas (ver [hasThigh] y [hasKnee]). Los que tienen
/// [sideArt] en false todavía no tienen dibujo de lado.
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
    sideArt: false,
  ),
  jeans(
    2,
    'Jeans Clásicos',
    'Azules de toda la vida',
    price: 30,
    rarity: Rarity.common,
  ),
  cargo(
    3,
    'Bermudas Cargo',
    'Bolsillos para todo',
    price: 30,
    rarity: Rarity.common,
    cut: PantsCut.short,
  ),
  tropical(
    4,
    'Bermuda Tropical',
    'Vacaciones en la cadera',
    price: 30,
    rarity: Rarity.common,
    cut: PantsCut.short,
  ),
  sport(
    5,
    'Deportivo Morado',
    'Con franja y puños',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  smurf(
    6,
    'Pantalón de Pitufo',
    'Blanco, de aldea azul',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  ogre(
    7,
    'Pantalón de Ogro',
    'Del pantano, con cuerda',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  pirate(
    8,
    'Pantalón Pirata',
    'Rotos de tanto navegar',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  camo(
    9,
    'Pantalón Camuflado',
    'Imposible de ver en el bosque',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  tutu(
    10,
    'Tutú de Bailarina',
    'Ligero como una pirueta',
    price: 45,
    rarity: Rarity.uncommon,
    cut: PantsCut.skirt,
  ),
  clyde(
    11,
    'Pantalón de Clyde',
    'Rayas y tirantes de los años 30',
    price: 60,
    rarity: Rarity.rare,
  ),
  bonnie(
    12,
    'Falda de Bonnie',
    'Con estilo y de fuga',
    price: 60,
    rarity: Rarity.rare,
    cut: PantsCut.skirt,
  ),
  overalls(
    13,
    'Overol de Fontanero',
    'Para saltar tuberías',
    price: 60,
    rarity: Rarity.rare,
  ),
  wizardSchool(
    14,
    'Falda del Colegio de Magia',
    'A cuadros y con hechizo',
    price: 60,
    rarity: Rarity.rare,
    cut: PantsCut.skirt,
  ),
  squid(
    15,
    'Pantalón del Juego',
    'Verde y sin vuelta atrás',
    price: 60,
    rarity: Rarity.rare,
  ),
  charro(
    16,
    'Pantalón de Charro',
    'Botonadura de plata',
    price: 60,
    rarity: Rarity.rare,
  ),
  godfather(
    17,
    'Pantalón del Padrino',
    'Una oferta que no podrás rechazar',
    price: 75,
    rarity: Rarity.epic,
  ),
  disco(
    18,
    'Pantalón Disco',
    'Sábado por la noche',
    price: 75,
    rarity: Rarity.epic,
  ),
  yellowSuit(
    19,
    'Mono Amarillo',
    'Para pelear con estilo',
    price: 75,
    rarity: Rarity.epic,
  ),
  clown(
    20,
    'Pantalón de Payaso',
    'Lunares y mucha risa',
    price: 75,
    rarity: Rarity.epic,
  ),
  neon(
    21,
    'Pantalón Neón',
    'Brilla en la red',
    price: 100,
    rarity: Rarity.legendary,
  );

  const PantsStyle(
    this.id,
    this.title,
    this.description, {
    required this.price,
    required this.rarity,
    this.cut = PantsCut.long,
    this.sideArt = true,
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

  /// Qué tanto cubre: largo, corto o falda.
  final PantsCut cut;

  /// Si ya tiene dibujo de lado (para caminar y para el reposo de lado).
  final bool sideArt;

  @override
  CosmeticCategory get category => CosmeticCategory.pants;

  /// Todos se compran: ninguno viene gratis.
  @override
  bool get isFree => false;

  static const String _root = 'assets/images/personaje';

  /// El dibujo de [view] (de lado, la cadera), o null si ese pantalón todavía
  /// no lo tiene.
  String? assetFor(CharacterView view) => switch (view) {
    CharacterView.frente => '$_root/frente/pantalones/pantalon_$id.png',
    CharacterView.lado => sideHipAsset,
    CharacterView.espalda => backAsset,
  };

  /// El dibujo de espalda: sin bragueta ni hebilla y con bolsillos traseros.
  /// El dorado no lo tiene todavía y usa el de frente.
  String get backAsset => id == 1
      ? '$_root/frente/pantalones/pantalon_$id.png'
      : '$_root/espalda/pantalones/pantalon_$id.png';

  /// De lado: la cintura y la cadera. Null si no tiene dibujo de lado.
  String? get sideHipAsset =>
      sideArt ? '$_root/lado/pantalones/pantalon_${id}_cadera.png' : null;

  /// De lado: lo que va sobre el muslo (las faldas no lo tienen).
  String? get sideThighAsset => sideArt && cut != PantsCut.skirt
      ? '$_root/lado/pantalones/pantalon_${id}_muslo.png'
      : null;

  /// De lado: lo que va sobre la pantorrilla (solo los pantalones largos).
  String? get sideKneeAsset => sideArt && cut == PantsCut.long
      ? '$_root/lado/pantalones/pantalon_${id}_rodilla.png'
      : null;

  /// La falda va por encima de las piernas; el resto, por debajo del muslo.
  bool get hipOverLegs => cut == PantsCut.skirt;

  /// Busca el pantalón por su [id]. Null si es 0 (ninguno) o no existe.
  static PantsStyle? fromId(int? id) {
    for (final style in values) {
      if (style.id == id) return style;
    }
    return null;
  }
}
