/// Niveles del protocolo de juego. Cada uno es un conjunto de cosas que una
/// versión de la app tiene que entender para jugar bien con las demás.
///
/// Es el **único lugar** con estos números: el resto del código usa los
/// nombres. Cuándo y cómo subirlo está en `docs/protocolo.md`.
abstract final class ProtocolLevel {
  /// La 1.0.0: un solo mapa. No escribe `protocol` ni `requiredProtocol`,
  /// así que lo que no tiene esos campos cuenta como este nivel.
  static const base = 1;

  /// Entiende `mapId` y `requiredProtocol`, y publica su `protocol` al
  /// entrar a una sala. No agrega nada que la 1.0.0 no pueda jugar.
  static const roomProtocol = 2;

  // Al agregar algo que una versión vieja no entiende (un mapa, un
  // minijuego, una acción...), se agrega aquí un nivel nuevo, por ejemplo
  // `static const candyMap = 3;`, y se sube [AppProtocol.current].
}

/// El protocolo de esta versión de la app.
abstract final class AppProtocol {
  /// Lo que entiende esta versión. Siempre el nivel más alto de
  /// [ProtocolLevel].
  static const current = ProtocolLevel.roomProtocol;

  /// El de las salas y jugadores guardados sin el campo.
  static const legacy = ProtocolLevel.base;

  /// Lo que necesita una partida que usa [features]: el mayor de sus
  /// `minProtocol`, o [legacy] si no usa nada especial.
  static int requiredFor(Iterable<ProtocolFeature> features) {
    var required = legacy;
    for (final feature in features) {
      if (feature.minProtocol > required) required = feature.minProtocol;
    }
    return required;
  }

  /// Si esta versión puede jugar algo que necesita [required].
  static bool supports(int required) => required <= current;
}

/// Algo de la partida que no todas las versiones de la app entienden: un
/// mapa, un minijuego, una acción, un sistema de objetos...
abstract interface class ProtocolFeature {
  /// El nivel desde el que la app lo entiende (un [ProtocolLevel]).
  int get minProtocol;
}
