import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/tile_effects.dart';

/// Convierte el estado y las acciones a mapas para guardarlos en Realtime
/// Database (`rooms/{id}/game` y `rooms/{id}/actions`), y de vuelta.
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
    );
  }

  Map<String, Object?> encodeAction(GameAction action) => switch (action) {
    RollDice(:final playerId) => {'type': 'roll', 'playerId': playerId},
    ChooseBranch(:final playerId, :final branch) => {
      'type': 'branch',
      'playerId': playerId,
      'branch': branch,
    },
    FinishMinigame(:final winnerIds) => {
      'type': 'minigame',
      'winnerIds': winnerIds,
    },
  };

  GameAction decodeAction(Map<Object?, Object?> data) {
    return switch (data['type']) {
      'roll' => RollDice(data['playerId'] as String),
      'branch' => ChooseBranch(
        data['playerId'] as String,
        _int(data['branch']),
      ),
      'minigame' => FinishMinigame([
        for (final id in data['winnerIds'] as List? ?? const []) id as String,
      ]),
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
    );
  }

  /// La base de datos puede devolver los números como int o como double, y
  /// no guarda los que valen null.
  int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}
