import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'package:party_tricks/services/game_engine/tile_effects.dart';

/// En qué momento de la ronda va la partida.
///
/// [shopping]: el jugador cayó en una tienda y está comprando; su turno
/// termina cuando sale.
enum GamePhase { rolling, choosingBranch, shopping, minigame, finished }

/// Estado de un jugador dentro de una partida.
class PlayerState {
  const PlayerState({
    required this.id,
    required this.username,
    this.position = 0,
    this.coins = 0,
    this.diamonds = 0,
    this.pendingEffect,
    this.minigamesWon = 0,
    this.negativeTiles = 0,
    this.purchases = 0,
    this.diceRolled = 0,
    this.diceTotal = 0,
    this.maxRolls = 0,
    this.positiveTiles = 0,
    this.specialTiles = 0,
    this.mainPathsTaken = 0,
    this.shortcutsTaken = 0,
    this.laps = 0,
    this.mapDiamonds = 0,
    this.inventory = const {},
    this.activeItems = const [],
    this.itemsUsed = 0,
    this.away = false,
    this.missedTurns = 0,
  });

  final String id;
  final String username;

  /// Casilla donde está parado.
  final int position;
  final int coins;
  final int diamonds;

  /// Efecto de una casilla especial que se aplica en su siguiente turno.
  final PendingEffect? pendingEffect;

  // Contadores para los diamantes finales (diseno_juego.md, sección 10).
  final int minigamesWon;
  final int negativeTiles;
  final int purchases;

  // Contadores para las estadísticas del jugador (decisiones.md, D-21).

  /// Veces que lanzó el dado y suma de lo que sacó.
  final int diceRolled;
  final int diceTotal;

  /// Veces que sacó el número más alto del dado (6, o 3 y 12 con efectos).
  final int maxRolls;

  /// Casillas positivas y especiales donde cayó (las negativas van arriba).
  final int positiveTiles;
  final int specialTiles;

  /// En las bifurcaciones: veces que siguió el camino principal o el atajo.
  final int mainPathsTaken;
  final int shortcutsTaken;

  /// Vueltas completas al mapa (veces que pasó por la salida).
  final int laps;

  /// Diamantes recogidos en el mapa.
  final int mapDiamonds;

  /// Mochila: cuántos tiene de cada ítem. Los que tiene en 0 no aparecen.
  final Map<ShopItem, int> inventory;

  /// Ítems que activó para su próxima tirada (dado extra e impulso).
  final List<ShopItem> activeItems;

  /// Ítems que gastó: los que activó y los pasivos que se usaron solos.
  final int itemsUsed;

  /// Se desconectó y el anfitrión le saltó el turno. Vuelve a false cuando
  /// juega de nuevo. Si termina la partida así, no gana XP ni premios
  /// (diseno_juego.md, sección 11).
  final bool away;

  /// Turnos que el anfitrión le saltó por estar desconectado.
  final int missedTurns;

  int itemCount(ShopItem item) => inventory[item] ?? 0;

  /// Suma o quita [delta] ítems de la mochila.
  PlayerState addItem(ShopItem item, int delta) {
    final count = itemCount(item) + delta;
    final updated = {...inventory}..remove(item);
    if (count > 0) updated[item] = count;
    return copyWith(inventory: updated);
  }

  /// Gasta un ítem de la mochila y lo cuenta como usado.
  PlayerState consumeItem(ShopItem item) {
    return addItem(item, -1).copyWith(itemsUsed: itemsUsed + 1);
  }

  /// Suma o resta monedas sin bajar de cero.
  PlayerState addCoins(int delta) {
    final total = coins + delta;
    return copyWith(coins: total < 0 ? 0 : total);
  }

  PlayerState copyWith({
    int? position,
    int? coins,
    int? diamonds,
    PendingEffect? pendingEffect,
    bool clearPendingEffect = false,
    int? minigamesWon,
    int? negativeTiles,
    int? purchases,
    int? diceRolled,
    int? diceTotal,
    int? maxRolls,
    int? positiveTiles,
    int? specialTiles,
    int? mainPathsTaken,
    int? shortcutsTaken,
    int? laps,
    int? mapDiamonds,
    Map<ShopItem, int>? inventory,
    List<ShopItem>? activeItems,
    int? itemsUsed,
    bool? away,
    int? missedTurns,
  }) {
    return PlayerState(
      id: id,
      username: username,
      position: position ?? this.position,
      coins: coins ?? this.coins,
      diamonds: diamonds ?? this.diamonds,
      pendingEffect: clearPendingEffect
          ? null
          : pendingEffect ?? this.pendingEffect,
      minigamesWon: minigamesWon ?? this.minigamesWon,
      negativeTiles: negativeTiles ?? this.negativeTiles,
      purchases: purchases ?? this.purchases,
      diceRolled: diceRolled ?? this.diceRolled,
      diceTotal: diceTotal ?? this.diceTotal,
      maxRolls: maxRolls ?? this.maxRolls,
      positiveTiles: positiveTiles ?? this.positiveTiles,
      specialTiles: specialTiles ?? this.specialTiles,
      mainPathsTaken: mainPathsTaken ?? this.mainPathsTaken,
      shortcutsTaken: shortcutsTaken ?? this.shortcutsTaken,
      laps: laps ?? this.laps,
      mapDiamonds: mapDiamonds ?? this.mapDiamonds,
      inventory: inventory ?? this.inventory,
      activeItems: activeItems ?? this.activeItems,
      itemsUsed: itemsUsed ?? this.itemsUsed,
      away: away ?? this.away,
      missedTurns: missedTurns ?? this.missedTurns,
    );
  }
}

/// Estado completo de una partida. No se modifica: cada acción crea uno nuevo.
class GameState {
  const GameState({
    required this.players,
    required this.turnOrder,
    required this.totalRounds,
    required this.diamondTileId,
    this.round = 1,
    this.turnIndex = 0,
    this.phase = GamePhase.rolling,
    this.stepsLeft = 0,
    this.lastRoll = 0,
    this.lastExtraRoll = 0,
    this.lastBoost = 0,
    this.traps = const {},
    this.minigame,
    this.lastMinigame,
  });

  /// Jugadores por id.
  final Map<String, PlayerState> players;

  /// Ids de los jugadores en el orden en que juegan.
  final List<String> turnOrder;
  final int totalRounds;

  /// Ronda actual, empieza en 1.
  final int round;

  /// Posición en [turnOrder] del jugador que tiene el turno.
  final int turnIndex;
  final GamePhase phase;

  /// Casilla donde está el diamante del mapa.
  final int diamondTileId;

  /// Pasos que le faltan al jugador cuando se detiene en una bifurcación.
  final int stepsLeft;

  /// Último número que salió en el dado.
  final int lastRoll;

  /// Lo que salió en el dado extra y las casillas del impulso en la última
  /// tirada, o 0 si no se usaron.
  final int lastExtraRoll;
  final int lastBoost;

  /// Trampas puestas: casilla -> id de quien la puso.
  final Map<int, String> traps;

  /// El minijuego en curso, solo en la fase [GamePhase.minigame].
  final MinigameState? minigame;

  /// Cómo terminó el último minijuego, para mostrarlo a todos.
  final MinigameResult? lastMinigame;

  String get currentPlayerId => turnOrder[turnIndex];

  PlayerState get currentPlayer => players[currentPlayerId]!;

  /// Copia del estado con [player] actualizado.
  GameState withPlayer(PlayerState player) {
    return copyWith(players: {...players, player.id: player});
  }

  GameState copyWith({
    Map<String, PlayerState>? players,
    int? round,
    int? turnIndex,
    GamePhase? phase,
    int? diamondTileId,
    int? stepsLeft,
    int? lastRoll,
    int? lastExtraRoll,
    int? lastBoost,
    Map<int, String>? traps,
    MinigameState? minigame,
    bool clearMinigame = false,
    MinigameResult? lastMinigame,
  }) {
    return GameState(
      players: players ?? this.players,
      turnOrder: turnOrder,
      totalRounds: totalRounds,
      round: round ?? this.round,
      turnIndex: turnIndex ?? this.turnIndex,
      phase: phase ?? this.phase,
      diamondTileId: diamondTileId ?? this.diamondTileId,
      stepsLeft: stepsLeft ?? this.stepsLeft,
      lastRoll: lastRoll ?? this.lastRoll,
      lastExtraRoll: lastExtraRoll ?? this.lastExtraRoll,
      lastBoost: lastBoost ?? this.lastBoost,
      traps: traps ?? this.traps,
      minigame: clearMinigame ? null : minigame ?? this.minigame,
      lastMinigame: lastMinigame ?? this.lastMinigame,
    );
  }
}
