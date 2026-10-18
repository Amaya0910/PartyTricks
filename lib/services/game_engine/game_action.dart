/// Lo que un jugador (o el anfitrión) le pide al motor.
sealed class GameAction {
  const GameAction();
}

/// El jugador que tiene el turno lanza el dado y avanza.
final class RollDice extends GameAction {
  const RollDice(this.playerId);

  final String playerId;
}

/// El jugador detenido en una bifurcación elige camino.
///
/// 0 = seguir el principal, 1 = el alterno.
final class ChooseBranch extends GameAction {
  const ChooseBranch(this.playerId, this.branch);

  final String playerId;
  final int branch;
}

/// Terminó el minijuego de la ronda. Puede haber varios ganadores.
final class FinishMinigame extends GameAction {
  const FinishMinigame(this.winnerIds);

  final List<String> winnerIds;
}
