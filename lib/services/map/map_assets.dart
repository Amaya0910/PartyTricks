/// Rutas de las imágenes del juego que no pertenecen a un mapa (moneda,
/// diamante y dados). Lo que cambia de un mapa a otro (camino, marcas,
/// flechas) sale del tema del mapa (`map_theme.dart`).
class MapAssets {
  const MapAssets._();

  static const _game = 'assets/images/juego';

  static const coin = '$_game/moneda.png';
  static const diamond = '$_game/diamante.png';

  /// Cara del dado con [value] puntos (de 1 a 6).
  static String dice(int value) => '$_game/dado_$value.png';
}
