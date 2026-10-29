import 'package:party_tricks/services/game_engine/shop_items.dart';

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

/// El jugador que está en una tienda compra un ítem.
final class BuyItem extends GameAction {
  const BuyItem(this.playerId, this.item);

  final String playerId;
  final ShopItem item;
}

/// El jugador sale de la tienda y termina su turno.
final class LeaveShop extends GameAction {
  const LeaveShop(this.playerId);

  final String playerId;
}

/// Antes de lanzar el dado, el jugador usa un ítem de su mochila: activa un
/// dado extra o el impulso, o pone una trampa en su casilla.
final class UseItem extends GameAction {
  const UseItem(this.playerId, this.item);

  final String playerId;
  final ShopItem item;
}

/// Solo el anfitrión: el jugador del turno se desconectó, así que se juega
/// por él lo mínimo para que la partida siga: pierde la tirada, toma el
/// camino principal en la bifurcación o sale de la tienda.
final class SkipTurn extends GameAction {
  const SkipTurn(this.playerId);

  final String playerId;
}

/// Terminó el minijuego de la ronda. Puede haber varios ganadores.
final class FinishMinigame extends GameAction {
  const FinishMinigame(this.winnerIds);

  final List<String> winnerIds;
}
