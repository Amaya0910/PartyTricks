/// Desde dónde se ve al personaje. Cada vista tiene su propia carpeta de arte
/// en `assets/images/personaje/<carpeta>/` (ojos, bocas y cuerpo); la cabeza
/// es la misma en las dos.
enum CharacterView {
  /// De frente: quieto (Inicio, Vestuario, sala de espera).
  frente,

  /// De lado: caminando por el mapa.
  lado;

  String get folder => name;
}
