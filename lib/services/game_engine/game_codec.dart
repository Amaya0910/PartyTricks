import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'package:party_tricks/services/game_engine/tile_effects.dart';

/// Convierte el estado y las acciones a mapas para guardarlos en Realtime
/// Database (`rooms/{id}/game` y `rooms/{id}/actions`), y de vuelta.
///
/// Los campos que faltan se leen vacíos, así las partidas guardadas antes de
/// las tiendas o de los minijuegos siguen funcionando.
class GameCodec {
  const GameCodec();

  Map<String, Object?> encodeState(GameState state) => {
    'players': {for (final p in state.players.values) p.id: _encodePlayer(p)},
    'turnOrder': state.turnOrder,
    'totalRounds': state.totalRounds,
    'round': state.round,
    'turnIndex': state.turnIndex,
    'phase': state.phase.name,
    'diamondTileId': state.diamondTileId,
    'stepsLeft': state.stepsLeft,
    'lastRoll': state.lastRoll,
    'lastExtraRoll': state.lastExtraRoll,
    'lastBoost': state.lastBoost,
    // Con claves "t17" y no "17": si las claves son números, la base de
    // datos puede devolver el mapa como lista.
    'traps': {
      for (final entry in state.traps.entries) 't${entry.key}': entry.value,
    },
    'minigame': switch (state.minigame) {
      final minigame? => _encodeMinigame(minigame),
      null => null,
    },
    'lastMinigame': switch (state.lastMinigame) {
      final result? => _encodeResult(result),
      null => null,
    },
  };

  GameState decodeState(Map<Object?, Object?> data) {
    final players = data['players'] as Map<Object?, Object?>;
    return GameState(
      players: {
        for (final entry in players.entries)
          entry.key as String: _decodePlayer(
            entry.key as String,
            entry.value as Map<Object?, Object?>,
          ),
      },
      turnOrder: [for (final id in data['turnOrder'] as List) id as String],
      totalRounds: _int(data['totalRounds']),
      round: _int(data['round']),
      turnIndex: _int(data['turnIndex']),
      phase: GamePhase.values.byName(data['phase'] as String),
      diamondTileId: _int(data['diamondTileId']),
      stepsLeft: _int(data['stepsLeft']),
      lastRoll: _int(data['lastRoll']),
      lastExtraRoll: _int(data['lastExtraRoll']),
      lastBoost: _int(data['lastBoost']),
      traps: {
        for (final entry in _map(data['traps']).entries)
          int.parse((entry.key as String).substring(1)): entry.value as String,
      },
      minigame: _decodeMinigame(data['minigame']),
      lastMinigame: _decodeResult(data['lastMinigame']),
    );
  }

  Map<String, Object?> encodeAction(GameAction action) => switch (action) {
    RollDice(:final playerId) => {'type': 'roll', 'playerId': playerId},
    ChooseBranch(:final playerId, :final branch) => {
      'type': 'branch',
      'playerId': playerId,
      'branch': branch,
    },
    BuyItem(:final playerId, :final item) => {
      'type': 'buy',
      'playerId': playerId,
      'item': item.name,
    },
    LeaveShop(:final playerId) => {'type': 'leaveShop', 'playerId': playerId},
    SkipTurn(:final playerId) => {'type': 'skip', 'playerId': playerId},
    UseItem(:final playerId, :final item) => {
      'type': 'useItem',
      'playerId': playerId,
      'item': item.name,
    },
    FinishMinigame(:final winnerIds) => {
      'type': 'minigame',
      'winnerIds': winnerIds,
    },
    MinigameMove(:final playerId, :final round, :final score) => {
      'type': 'minigameMove',
      'playerId': playerId,
      'round': round,
      'score': score,
    },
    MinigameTimeout(:final round, :final step) => {
      'type': 'minigameTimeout',
      'round': round,
      'step': step,
    },
  };

  GameAction decodeAction(Map<Object?, Object?> data) {
    return switch (data['type']) {
      'roll' => RollDice(data['playerId'] as String),
      'branch' => ChooseBranch(
        data['playerId'] as String,
        _int(data['branch']),
      ),
      'buy' => BuyItem(data['playerId'] as String, _item(data['item'])),
      'leaveShop' => LeaveShop(data['playerId'] as String),
      'skip' => SkipTurn(data['playerId'] as String),
      'useItem' => UseItem(data['playerId'] as String, _item(data['item'])),
      'minigame' => FinishMinigame([
        for (final id in data['winnerIds'] as List? ?? const []) id as String,
      ]),
      'minigameMove' => MinigameMove(
        data['playerId'] as String,
        _int(data['round']),
        _int(data['score']),
      ),
      'minigameTimeout' => MinigameTimeout(
        _int(data['round']),
        _int(data['step']),
      ),
      final type => throw FormatException('Acción desconocida: $type'),
    };
  }

  Map<String, Object?> _encodePlayer(PlayerState p) => {
    'username': p.username,
    'position': p.position,
    'coins': p.coins,
    'diamonds': p.diamonds,
    'pendingEffect': p.pendingEffect?.name,
    'minigamesWon': p.minigamesWon,
    'negativeTiles': p.negativeTiles,
    'purchases': p.purchases,
    'diceRolled': p.diceRolled,
    'diceTotal': p.diceTotal,
    'maxRolls': p.maxRolls,
    'positiveTiles': p.positiveTiles,
    'specialTiles': p.specialTiles,
    'mainPathsTaken': p.mainPathsTaken,
    'shortcutsTaken': p.shortcutsTaken,
    'laps': p.laps,
    'mapDiamonds': p.mapDiamonds,
    'inventory': {
      for (final entry in p.inventory.entries) entry.key.name: entry.value,
    },
    'activeItems': [for (final item in p.activeItems) item.name],
    'itemsUsed': p.itemsUsed,
    'away': p.away,
    'missedTurns': p.missedTurns,
  };

  PlayerState _decodePlayer(String id, Map<Object?, Object?> data) {
    final effect = data['pendingEffect'] as String?;
    return PlayerState(
      id: id,
      username: data['username'] as String,
      position: _int(data['position']),
      coins: _int(data['coins']),
      diamonds: _int(data['diamonds']),
      pendingEffect: effect == null
          ? null
          : PendingEffect.values.byName(effect),
      minigamesWon: _int(data['minigamesWon']),
      negativeTiles: _int(data['negativeTiles']),
      purchases: _int(data['purchases']),
      diceRolled: _int(data['diceRolled']),
      diceTotal: _int(data['diceTotal']),
      maxRolls: _int(data['maxRolls']),
      positiveTiles: _int(data['positiveTiles']),
      specialTiles: _int(data['specialTiles']),
      mainPathsTaken: _int(data['mainPathsTaken']),
      shortcutsTaken: _int(data['shortcutsTaken']),
      laps: _int(data['laps']),
      mapDiamonds: _int(data['mapDiamonds']),
      // Un ítem que esta versión no conoce se ignora en vez de romper.
      inventory: {
        for (final entry in _map(data['inventory']).entries)
          if (_knownItem(entry.key) case final item?)
            if (_int(entry.value) > 0) item: _int(entry.value),
      },
      activeItems: [
        for (final name in _list(data['activeItems'])) ?_knownItem(name),
      ],
      itemsUsed: _int(data['itemsUsed']),
      away: data['away'] as bool? ?? false,
      missedTurns: _int(data['missedTurns']),
    );
  }

  Map<String, Object?> _encodeMinigame(MinigameState minigame) => {
    'type': minigame.type.name,
    'round': minigame.round,
    'players': minigame.players,
    'step': minigame.step,
    'targetMs': minigame.targetMs,
    'delayMs': minigame.delayMs,
    'capacity': minigame.capacity,
    'pumps': minigame.pumps,
    'turn': minigame.turn,
    'scores': minigame.scores,
    'out': minigame.out,
  };

  /// Un minijuego que esta versión no conoce se lee como ninguno.
  MinigameState? _decodeMinigame(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final type = MinigameType.byId(value['type']);
    if (type == null) return null;
    return MinigameState(
      type: type,
      round: _int(value['round']),
      players: _strings(value['players']),
      step: _int(value['step']),
      targetMs: _int(value['targetMs']),
      delayMs: _int(value['delayMs']),
      capacity: _int(value['capacity']),
      pumps: _int(value['pumps']),
      turn: _int(value['turn']),
      scores: _scores(value['scores']),
      out: _strings(value['out']),
    );
  }

  Map<String, Object?> _encodeResult(MinigameResult result) => {
    'type': result.type.name,
    'round': result.round,
    'winnerIds': result.winnerIds,
    'targetMs': result.targetMs,
    'scores': result.scores,
    'tiebreak': result.tiebreak,
    'out': result.out,
  };

  MinigameResult? _decodeResult(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final type = MinigameType.byId(value['type']);
    if (type == null) return null;
    return MinigameResult(
      type: type,
      round: _int(value['round']),
      winnerIds: _strings(value['winnerIds']),
      targetMs: _int(value['targetMs']),
      scores: _scores(value['scores']),
      tiebreak: {
        for (final entry in _map(value['tiebreak']).entries)
          entry.key as String: [
            for (final roll in _list(entry.value)) _int(roll),
          ],
      },
      out: _strings(value['out']),
    );
  }

  List<String> _strings(Object? value) => [
    for (final item in _list(value)) item as String,
  ];

  Map<String, int> _scores(Object? value) => {
    for (final entry in _map(value).entries)
      entry.key as String: _int(entry.value),
  };

  ShopItem _item(Object? name) {
    final item = _knownItem(name);
    if (item == null) throw FormatException('Ítem desconocido: $name');
    return item;
  }

  ShopItem? _knownItem(Object? name) {
    for (final item in ShopItem.values) {
      if (item.name == name) return item;
    }
    return null;
  }

  /// La base de datos no guarda los mapas vacíos.
  Map<Object?, Object?> _map(Object? value) =>
      value as Map<Object?, Object?>? ?? const {};

  /// Las listas pueden volver como mapa ("0", "1"...) si les faltan
  /// posiciones.
  Iterable<Object?> _list(Object? value) => switch (value) {
    final List<Object?> list => list.whereType<Object>(),
    final Map<Object?, Object?> map => map.values,
    _ => const [],
  };

  /// La base de datos puede devolver los números como int o como double, y
  /// no guarda los que valen null.
  int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}
