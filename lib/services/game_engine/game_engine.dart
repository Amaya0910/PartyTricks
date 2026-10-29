import 'dart:math';

import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
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
    this.itemRules = const ItemRules(),
    this.minigameRules = const MinigameRules(),
    this.minigames = const [],
    this.startingCoins = 10,
    this.minigameCoins = 10,
  });

  final BoardLayout board;
  final RandomSource random;
  final TileEffects tileEffects;
  final ItemRules itemRules;
  final MinigameRules minigameRules;

  /// Minijuegos que pueden salir; cada ronda se sortea uno. Sin ninguno, la
  /// ronda espera un [FinishMinigame] con los ganadores (así funcionan las
  /// pruebas de antes de los minijuegos).
  final List<MinigameType> minigames;
  final int startingCoins;
  final int minigameCoins;

  MinigameJudge get _judge =>
      MinigameJudge(random: random, rules: minigameRules);

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
      RollDice(:final playerId) => _roll(_back(state, playerId), playerId),
      ChooseBranch(:final playerId, :final branch) => _chooseBranch(
        _back(state, playerId),
        playerId,
        branch,
      ),
      BuyItem(:final playerId, :final item) => _buy(
        _back(state, playerId),
        playerId,
        item,
      ),
      LeaveShop(:final playerId) => _leaveShop(
        _back(state, playerId),
        playerId,
      ),
      UseItem(:final playerId, :final item) => _useItem(
        _back(state, playerId),
        playerId,
        item,
      ),
      SkipTurn(:final playerId) => _skip(state, playerId),
      FinishMinigame(:final winnerIds) => _finishMinigame(state, winnerIds),
      MinigameMove(:final playerId, :final round, :final score) =>
        _playMinigame(_back(state, playerId), playerId, round, score),
      MinigameTimeout(:final round, :final step) => _minigameTimeout(
        state,
        round,
        step,
      ),
    };
  }

  /// Si el que juega estaba marcado como ausente, ya volvió.
  GameState _back(GameState state, String playerId) {
    final player = state.players[playerId];
    if (player == null || !player.away) return state;
    return state.withPlayer(player.copyWith(away: false));
  }

  GameState _skip(GameState state, String playerId) {
    if (state.phase == GamePhase.minigame ||
        state.phase == GamePhase.finished) {
      throw StateError('No hay un turno que saltar (${state.phase.name})');
    }
    if (state.currentPlayerId != playerId) {
      throw StateError('No es el turno de $playerId');
    }
    final player = state.currentPlayer;
    final marked = state.withPlayer(
      player.copyWith(away: true, missedTurns: player.missedTurns + 1),
    );
    return switch (state.phase) {
      GamePhase.choosingBranch => _chooseBranch(marked, playerId, 0),
      _ => _nextTurn(marked),
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
    // Los ítems activados se gastaron al usarlos; aquí solo hacen efecto.
    final extraDie = player.activeItems.where((item) => item.isExtraDie);
    final extraRoll = extraDie.isEmpty
        ? 0
        : random.rollDie(extraDie.first.extraDieSides);
    final boost = player.activeItems.contains(ShopItem.movementBoost)
        ? itemRules.boostSteps
        : 0;
    // Las estadísticas de dados solo cuentan el dado normal.
    player = player.copyWith(
      clearPendingEffect: true,
      activeItems: const [],
      diceRolled: player.diceRolled + 1,
      diceTotal: player.diceTotal + roll,
      maxRolls: roll == sides ? player.maxRolls + 1 : null,
    );
    final rolled = state
        .withPlayer(player)
        .copyWith(lastRoll: roll, lastExtraRoll: extraRoll, lastBoost: boost);
    return _move(rolled, roll + extraRoll + boost);
  }

  /// Por qué el jugador del turno no puede comprar [item], o null si puede.
  /// La pantalla lo usa para desactivar el botón con el motivo.
  String? whyCannotBuy(GameState state, ShopItem item) {
    final player = state.currentPlayer;
    if (player.coins < item.price) return 'No te alcanzan las monedas';
    if (player.itemCount(item) >= itemRules.maxPerItem) {
      return 'Ya tienes ${itemRules.maxPerItem}';
    }
    return null;
  }

  /// Por qué el jugador del turno no puede usar [item], o null si puede.
  String? whyCannotUse(GameState state, ShopItem item) {
    final player = state.currentPlayer;
    if (item.passive) return 'Se usa solo';
    if (player.itemCount(item) == 0) return 'No tienes';
    if (item == ShopItem.trap) {
      final tile = board.tile(player.position);
      if (tile.type == TileType.start || tile.type == TileType.shop) {
        return 'No se puede poner en esta casilla';
      }
      if (state.traps.containsKey(tile.id)) return 'Ya hay una trampa aquí';
      return null;
    }
    // Un solo dado extra y un solo impulso por tirada.
    final repeated = player.activeItems.any(
      (active) => active == item || (active.isExtraDie && item.isExtraDie),
    );
    return repeated ? 'Ya tienes uno activo' : null;
  }

  GameState _buy(GameState state, String playerId, ShopItem item) {
    _checkTurn(state, playerId, GamePhase.shopping);
    final problem = whyCannotBuy(state, item);
    if (problem != null) throw StateError('${item.name}: $problem');
    final player = state.currentPlayer;
    return state.withPlayer(
      player
          .addCoins(-item.price)
          .addItem(item, 1)
          .copyWith(purchases: player.purchases + 1),
    );
  }

  GameState _leaveShop(GameState state, String playerId) {
    _checkTurn(state, playerId, GamePhase.shopping);
    return _nextTurn(state);
  }

  GameState _useItem(GameState state, String playerId, ShopItem item) {
    _checkTurn(state, playerId, GamePhase.rolling);
    final problem = whyCannotUse(state, item);
    if (problem != null) throw StateError('${item.name}: $problem');
    final player = state.currentPlayer;
    if (item == ShopItem.trap) {
      return state
          .withPlayer(player.consumeItem(item))
          .copyWith(traps: {...state.traps, player.position: player.id});
    }
    return state.withPlayer(
      player
          .consumeItem(item)
          .copyWith(activeItems: [...player.activeItems, item]),
    );
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

  /// Mueve al jugador una casilla. Si pasa por el diamante, se lo lleva; si
  /// pasa por la trampa de otro, salta. Si llega a la salida, completó una
  /// vuelta.
  GameState _step(GameState state, int tileId) {
    var player = state.currentPlayer.copyWith(position: tileId);
    if (tileId == BoardLayout.startId) {
      player = player.copyWith(laps: player.laps + 1);
    }
    var diamondTileId = state.diamondTileId;
    if (tileId == diamondTileId) {
      var won = 1;
      if (player.itemCount(ShopItem.diamondBoost) > 0) {
        won++;
        player = player.consumeItem(ShopItem.diamondBoost);
      }
      player = player.copyWith(
        diamonds: player.diamonds + won,
        mapDiamonds: player.mapDiamonds + won,
      );
      diamondTileId = _randomDiamondTile(exclude: tileId);
    }
    final moved = state
        .withPlayer(player)
        .copyWith(diamondTileId: diamondTileId);
    return _springTrap(moved, tileId);
  }

  /// La trampa de otro jugador le roba monedas al que pasa, salvo que tenga
  /// escudo. En los dos casos la trampa se gasta. La propia no hace nada.
  GameState _springTrap(GameState state, int tileId) {
    final ownerId = state.traps[tileId];
    final victim = state.currentPlayer;
    if (ownerId == null || ownerId == victim.id) return state;
    final traps = {...state.traps}..remove(tileId);
    if (victim.itemCount(ShopItem.shield) > 0) {
      return state
          .withPlayer(victim.consumeItem(ShopItem.shield))
          .copyWith(traps: traps);
    }
    final stolen = min(victim.coins, itemRules.trapCoins);
    var next = state.withPlayer(victim.addCoins(-stolen));
    final owner = next.players[ownerId];
    if (owner != null) next = next.withPlayer(owner.addCoins(stolen));
    return next.copyWith(traps: traps);
  }

  /// Aplica el efecto de la casilla donde cayó y pasa el turno. Si cayó en
  /// una tienda, el turno sigue hasta que salga de ella.
  GameState _land(GameState state) {
    var player = state.currentPlayer;
    final tile = board.tile(player.position);
    final outcome = tileEffects.resolve(tile.type, random);
    var coinDelta = outcome.coinDelta;
    if (tile.type == TileType.negative &&
        player.itemCount(ShopItem.shield) > 0) {
      coinDelta = 0;
      player = player.consumeItem(ShopItem.shield);
    }
    final updated = player
        .addCoins(coinDelta)
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
    final landed = state.withPlayer(updated).copyWith(stepsLeft: 0);
    if (tile.type == TileType.shop) {
      return landed.copyWith(phase: GamePhase.shopping);
    }
    return _nextTurn(landed);
  }

  /// Pasa al siguiente jugador; si ya jugaron todos, viene el minijuego.
  GameState _nextTurn(GameState state) {
    final next = state.turnIndex + 1;
    if (next < state.turnOrder.length) {
      return state.copyWith(turnIndex: next, phase: GamePhase.rolling);
    }
    return _startMinigame(
      state.copyWith(turnIndex: 0, phase: GamePhase.minigame),
    );
  }

  /// Sortea el minijuego de la ronda. Juegan los que no están ausentes.
  GameState _startMinigame(GameState state) {
    if (minigames.isEmpty) return state;
    final type = minigames.length == 1
        ? minigames.first
        : minigames[random.nextInt(0, minigames.length - 1)];
    final players = [
      for (final id in state.turnOrder)
        if (state.players[id]?.away == false) id,
    ];
    return _afterMinigame(state, _judge.start(type, state.round, players));
  }

  GameState _playMinigame(
    GameState state,
    String playerId,
    int round,
    int score,
  ) {
    final minigame = _currentMinigame(state, round);
    return _afterMinigame(state, _judge.play(minigame, playerId, score));
  }

  GameState _minigameTimeout(GameState state, int round, int step) {
    if (state.phase != GamePhase.minigame || state.round != round) {
      throw StateError('No hay un minijuego de la ronda $round');
    }
    // Partida de antes de los minijuegos: se cierra la ronda sin ganador.
    if (state.minigame == null) return _finishMinigame(state, const []);
    final minigame = _currentMinigame(state, round);
    return _afterMinigame(state, _judge.timeout(minigame, step));
  }

  MinigameState _currentMinigame(GameState state, int round) {
    final minigame = state.minigame;
    if (state.phase != GamePhase.minigame || minigame == null) {
      throw StateError('No hay un minijuego en curso');
    }
    if (minigame.round != round) {
      throw StateError('El minijuego es de la ronda ${minigame.round}');
    }
    return minigame;
  }

  /// Si el minijuego sigue, lo guarda; si terminó, paga a los ganadores.
  GameState _afterMinigame(GameState state, MinigameOutcome outcome) {
    final result = outcome.result;
    if (result == null) return state.copyWith(minigame: outcome.state);
    return _finishMinigame(state, result.winnerIds, result: result);
  }

  GameState _finishMinigame(
    GameState state,
    List<String> winnerIds, {
    MinigameResult? result,
  }) {
    if (state.phase != GamePhase.minigame) {
      throw StateError('No hay un minijuego en curso');
    }
    var current = state.copyWith(clearMinigame: true, lastMinigame: result);
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
