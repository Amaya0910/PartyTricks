/// Desde dónde se ve al personaje. Cada vista tiene su propia carpeta de arte
/// en `assets/images/personaje/<carpeta>/` (ojos, bocas y cuerpo); la cabeza
/// es la misma en las dos.
enum CharacterView {
  /// De frente: quieto (Inicio, Vestuario, sala de espera).
  frente,

  /// De lado: caminando por el mapa.
  lado,

  /// De espalda: caminando hacia arriba en el mapa, y en el Vestuario. No
  /// tiene cara (ojos y boca no se ven); la ropa y el cabello usan su propio
  /// dibujo de espalda o, si no lo tienen, el de frente.
  espalda;

  String get folder => name;
}
