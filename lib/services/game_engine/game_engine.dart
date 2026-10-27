import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/services/game_engine/tile_effects.dart';
import 'package:party_tricks/services/game_engine/turn_order_resolver.dart';

/// Reglas de la partida: recibe un estado y una acción y devuelve el estado
/// nuevo. No guarda nada; el teléfono anfitrión lo usa y sube el resultado.
///
/// Las monedas iniciales y las del minijuego son provisionales.
class GameEngine {
  const GameEngine({
    required this.board,
    required this.random,
    this.tileEffects = const TileEffects(),
    this.startingCoins = 10,
    this.minigameCoins = 10,
  });

  final BoardLayout board;
  final RandomSource random;
  final TileEffects tileEffects;
  final int startingCoins;
  final int minigameCoins;

  /// Arma la partida con el orden de la tirada inicial.
  GameState start({
    required List<InitialRoll> initialRolls,
    required int totalRounds,
  }) {
    return GameState(
      players: {
        for (final roll in initialRolls)
          roll.playerId: PlayerState(
            id: roll.playerId,
            username: roll.username,
            coins: startingCoins,
          ),
      },
      turnOrder: const TurnOrderResolver().resolve(initialRolls),
      totalRounds: totalRounds,
      diamondTileId: _randomDiamondTile(exclude: BoardLayout.startId),
    );
  }

  /// Aplica [action]. Lanza [StateError] si no se puede hacer en este momento.
  GameState apply(GameState state, GameAction action) {
    return switch (action) {
      RollDice(:final playerId) => _roll(state, playerId),
      ChooseBranch(:final playerId, :final branch) => _chooseBranch(
        state,
        playerId,
        branch,
      ),
      FinishMinigame(:final winnerIds) => _finishMinigame(state, winnerIds),
    };
  }

  GameState _roll(GameState state, String playerId) {
    _checkTurn(state, playerId, GamePhase.rolling);
    var player = state.currentPlayer;
    var sides = 6;
    switch (player.pendingEffect) {
      case PendingEffect.die3:
        sides = 3;
      case PendingEffect.die12:
        sides = 12;
      case PendingEffect.backToStart:
        player = player.copyWith(position: BoardLayout.startId);
      case PendingEffect.loseCoins:
        player = player.addCoins(-tileEffects.specialCoins);
      case PendingEffect.gainCoins:
        player = player.addCoins(tileEffects.specialCoins);
      case null:
        break;
    }
    final roll = random.rollDie(sides);
    player = player.copyWith(
      clearPendingEffect: true,
      diceRolled: player.diceRolled + 1,
      diceTotal: player.diceTotal + roll,
      maxRolls: roll == sides ? player.maxRolls + 1 : null,
    );
    return _move(state.withPlayer(player).copyWith(lastRoll: roll), roll);
  }

  GameState _chooseBranch(GameState state, String playerId, int branch) {
    _checkTurn(state, playerId, GamePhase.choosingBranch);
    final fork = board.tile(state.currentPlayer.position);
    if (branch < 0 || branch >= fork.next.length) {
      throw StateError('El camino $branch no existe');
    }
    final player = state.currentPlayer;
    final counted = state.withPlayer(
      branch == 0
          ? player.copyWith(mainPathsTaken: player.mainPathsTaken + 1)
          : player.copyWith(shortcutsTaken: player.shortcutsTaken + 1),
    );
    final moved = _step(counted, fork.next[branch]);
    return _move(moved, state.stepsLeft - 1);
  }

  /// Avanza casilla por casilla. Si llega a una bifurcación con pasos
  /// pendientes, se detiene para que el jugador elija camino.
  GameState _move(GameState state, int steps) {
    var current = state;
    for (var left = steps; left > 0; left--) {
      final tile = board.tile(current.currentPlayer.position);
      if (tile.isFork) {
        return current.copyWith(
          phase: GamePhase.choosingBranch,
          stepsLeft: left,
        );
      }
      current = _step(current, tile.next.first);
    }
    return _land(current);
  }

  /// Mueve al jugador una casilla. Si pasa por el diamante, se lo lleva.
  /// Si llega a la salida, completó una vuelta.
  GameState _step(GameState state, int tileId) {
    var player = state.currentPlayer.copyWith(position: tileId);
    if (tileId == BoardLayout.startId) {
      player = player.copyWith(laps: player.laps + 1);
    }
    var diamondTileId = state.diamondTileId;
    if (tileId == diamondTileId) {
      player = player.copyWith(
        diamonds: player.diamonds + 1,
        mapDiamonds: player.mapDiamonds + 1,
      );
      diamondTileId = _randomDiamondTile(exclude: tileId);
    }
    return state.withPlayer(player).copyWith(diamondTileId: diamondTileId);
  }

  /// Aplica el efecto de la casilla donde cayó y pasa el turno.
  GameState _land(GameState state) {
    final player = state.currentPlayer;
    final tile = board.tile(player.position);
    final outcome = tileEffects.resolve(tile.type, random);
    final updated = player
        .addCoins(outcome.coinDelta)
        .copyWith(
          pendingEffect: outcome.pendingEffect,
          negativeTiles: tile.type == TileType.negative
              ? player.negativeTiles + 1
              : null,
          positiveTiles: tile.type == TileType.positive
              ? player.positiveTiles + 1
              : null,
          specialTiles: tile.type == TileType.special
              ? player.specialTiles + 1
              : null,
        );
    return _nextTurn(state.withPlayer(updated).copyWith(stepsLeft: 0));
  }

  /// Pasa al siguiente jugador; si ya jugaron todos, viene el minijuego.
  GameState _nextTurn(GameState state) {
    final next = state.turnIndex + 1;
    if (next < state.turnOrder.length) {
      return state.copyWith(turnIndex: next, phase: GamePhase.rolling);
    }
    return state.copyWith(turnIndex: 0, phase: GamePhase.minigame);
  }

  GameState _finishMinigame(GameState state, List<String> winnerIds) {
    if (state.phase != GamePhase.minigame) {
      throw StateError('No hay un minijuego en curso');
    }
    var current = state;
    for (final id in winnerIds.toSet()) {
      final winner = current.players[id];
      if (winner == null) throw StateError('El jugador $id no existe');
      current = current.withPlayer(
        winner
            .addCoins(minigameCoins)
            .copyWith(minigamesWon: winner.minigamesWon + 1),
      );
    }
    if (state.round >= state.totalRounds) {
      return current.copyWith(phase: GamePhase.finished);
    }
    return current.copyWith(round: state.round + 1, phase: GamePhase.rolling);
  }

  void _checkTurn(GameState state, String playerId, GamePhase phase) {
    if (state.phase != phase) {
      throw StateError('No se puede hacer eso ahora (${state.phase.name})');
    }
    if (state.currentPlayerId != playerId) {
      throw StateError('No es el turno de $playerId');
    }
  }

  /// Casilla al azar para el diamante, sin contar la salida ni las tiendas.
  int _randomDiamondTile({required int exclude}) {
    final candidates = [
      for (final tile in board.tiles)
        if (tile.id != exclude &&
            tile.type != TileType.start &&
            tile.type != TileType.shop)
          tile.id,
    ];
    return candidates[random.nextInt(0, candidates.length - 1)];
  }
}
