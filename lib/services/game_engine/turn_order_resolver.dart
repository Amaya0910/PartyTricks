/// Resultado de la tirada inicial de un jugador.
class InitialRoll {
  const InitialRoll({
    required this.playerId,
    required this.username,
    required this.value,
  });

  final String playerId;
  final String username;
  final int value;
}

/// Calcula el orden de juego a partir de la tirada inicial.
///
/// Juega primero quien saca el número más alto. Si hay empate, va de
/// último el que tenga el nombre de usuario más cercano a la Z.
class TurnOrderResolver {
  const TurnOrderResolver();

  /// Devuelve los ids de los jugadores en el orden en que juegan.
  List<String> resolve(List<InitialRoll> rolls) {
    final sorted = [...rolls]
      ..sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        if (byValue != 0) return byValue;
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
    return [for (final roll in sorted) roll.playerId];
  }
}
