import 'package:party_tricks/models/rarity.dart';

/// Una capa del PNG de una boca: su archivo y si toma el color elegido.
class MouthLayerSpec {
  const MouthLayerSpec(this.asset, {required this.tinted});

  final String asset;

  /// Si su parte blanca toma el color de la boca. Si no, se dibuja tal cual.
  final bool tinted;
}

/// Bocas del personaje. En el perfil se guarda solo el [number].
///
/// Cada boca es un PNG del mismo lienzo que el personaje (512x768) en
/// assets/images/personaje/bocas/. Algunas vienen en dos capas
/// (`boca_<n>_relleno.png` y `boca_<n>_linea.png`) y otras en un solo PNG
/// (`boca_<n>.png`).
///
/// El color se aplica con la misma técnica que los ojos (modulate): lo
/// blanco toma el color y lo negro sigue negro. Solo se tiñe la capa que
/// tiene el blanco; las bocas sin blanco o que no deben cambiar ([tintable]
/// false: 1, 9 y 10) se dibujan como están. Sin color, lo blanco toma el tono de piel.
///
/// Los de [price] 0 los tienen todos desde el inicio; los demás se compran
/// con monedas en la Tienda. Los precios también están en
/// `firestore.rules` (`mouthPrice`, D-30): si cambian aquí, hay que
/// cambiarlos allá o las compras se rechazarán.
enum MouthStyle {
  boca1(
    1,
    'Boca Carcajada',
    'Una risa a todo pulmón',
    layered: true,
    tintable: false,
  ),
  boca2(
    2,
    'Boca Traviesa',
    'Con labial para dar un beso',
    price: 30,
    rarity: Rarity.common,
  ),
  boca3(3, 'Boca Chiquita', 'Pequeña pero con dientes'),
  boca4(
    4,
    'Boca Radiante',
    'Sonrisa de oreja a oreja',
    price: 30,
    rarity: Rarity.common,
  ),
  boca5(
    5,
    'Boca Titubeante',
    'Siempre a punto de tartamudear',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  boca6(
    6,
    'Boca Sospechosa',
    'Media sonrisa de lado',
    price: 45,
    rarity: Rarity.uncommon,
  ),
  boca7(
    7,
    'Boca Nerviosa',
    'Ondulando de los nervios',
    price: 60,
    rarity: Rarity.rare,
  ),
  boca8(
    8,
    'Boca Pícara',
    'Un gesto que esconde algo',
    layered: true,
    price: 60,
    rarity: Rarity.rare,
  ),
  boca9(
    9,
    'Boca Bromista',
    'Sacando la lengua',
    tintable: false,
    price: 75,
    rarity: Rarity.epic,
  ),
  boca10(
    10,
    'Boca Sorprendida',
    '¡No me lo esperaba!',
    tintable: false,
    price: 75,
    rarity: Rarity.epic,
  );

  const MouthStyle(
    this.number,
    this.title,
    this.description, {
    this.layered = false,
    this.tintable = true,
    this.price = 0,
    this.rarity = Rarity.common,
  });

  /// Número del archivo y del nombre corto que se ve en el Vestuario
  /// ("Boca 7").
  final int number;

  /// Nombre y descripción para la Tienda.
  final String title;
  final String description;

  /// Si viene en dos capas (relleno + línea).
  final bool layered;

  /// Si su parte blanca puede tomar color. Las que no (1, 9 y 10) se ven
  /// siempre igual.
  final bool tintable;

  /// Precio en monedas. 0 si viene gratis con la cuenta.
  final int price;

  /// Qué tan rara es: define con qué frecuencia sale en los cofres.
  final Rarity rarity;

  /// Si lo tienen todos desde el inicio.
  bool get isFree => price == 0;

  /// Boca de quien todavía no ha elegido una.
  static const MouthStyle defaultStyle = boca1;

  static const String _folder = 'assets/images/personaje/bocas';

  /// Capas de abajo hacia arriba.
  List<MouthLayerSpec> get layers {
    if (!layered) {
      return [MouthLayerSpec('$_folder/boca_$number.png', tinted: tintable)];
    }
    return [
      MouthLayerSpec('$_folder/boca_${number}_relleno.png', tinted: false),
      MouthLayerSpec('$_folder/boca_${number}_linea.png', tinted: tintable),
    ];
  }

  /// Busca la boca por número (por si en Firestore queda un valor viejo o
  /// que ya no existe, devuelve [defaultStyle]).
  static MouthStyle fromNumber(int? number) {
    for (final style in values) {
      if (style.number == number) return style;
    }
    return defaultStyle;
  }
}
