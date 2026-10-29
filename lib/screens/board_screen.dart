import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/stats_controller.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/map_providers.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/services/stats/match_time_tracker.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/board_view.dart';
import 'package:party_tricks/widgets/map_items_dialog.dart';
import 'package:party_tricks/widgets/map/board_map_view.dart';

/// Pantalla de la partida: el tablero, los jugadores y lo que toca hacer.
///
/// En el teléfono del creador también corre el anfitrión, que aplica las
/// acciones de todos.
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key, required this.roomId, required this.isHost});

  final String roomId;
  final bool isHost;

  static Route<void> route(String roomId, {required bool isHost}) {
    return MaterialPageRoute(
      builder: (_) => BoardScreen(roomId: roomId, isHost: isHost),
    );
  }

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  void Function()? _stopHost;

  /// Mide la partida para las estadísticas (tiempo jugando y en minijuegos).
  final _timeTracker = MatchTimeTracker();

  /// Para guardar la partida en las estadísticas una sola vez.
  bool _statsRecorded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isHost) {
      _stopHost = ref.read(gameServiceProvider).runHost(widget.roomId);
    }
  }

  @override
  void dispose() {
    _stopHost?.call();
    super.dispose();
  }

  void _send(GameAction action) {
    ref.read(gameServiceProvider).sendAction(widget.roomId, action);
  }

  void _openItems(String myId, ItemsMode mode) {
    MapItemsDialog.show(
      context,
      roomId: widget.roomId,
      myId: myId,
      mode: mode,
      onAction: _send,
    );
  }

  /// Cada jugador guarda sus propias estadísticas al terminar la partida.
  void _onGameChanged(GameState? game) {
    if (game == null) return;
    _timeTracker.onPhase(game.phase);
    if (game.phase != GamePhase.finished || _statsRecorded) return;
    _statsRecorded = true;
    ref
        .read(statsControllerProvider)
        .recordFinishedMatch(
          roomId: widget.roomId,
          game: game,
          tracker: _timeTracker,
          isHost: widget.isHost,
          isPublic:
              ref.read(roomProvider(widget.roomId)).value?.isPublic ?? false,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      gameProvider(widget.roomId),
      (_, next) => _onGameChanged(next.value),
    );
    final game = ref.watch(gameProvider(widget.roomId)).value;
    final me = ref.watch(roomIdentityProvider).value;
    final mapView = game == null || me == null ? null : _mapView(game, me.uid);
    return PopScope(
      // Salir a mitad de partida llega con feature/disconnections.
      canPop: game?.phase == GamePhase.finished,
      child: Scaffold(
        backgroundColor: AppColors.screenBackground,
        body: SafeArea(
          child: game == null || me == null
              ? const Center(child: Text('Preparando la partida...'))
              : Column(
                  children: [
                    Expanded(
                      child:
                          mapView ??
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: BoardView(
                              board: ref.watch(boardProvider),
                              state: game,
                            ),
                          ),
                    ),
                    SizedBox(
                      height: _Panel.height,
                      child: _Panel(
                        game: game,
                        myId: me.uid,
                        isHost: widget.isHost,
                        branchButtons: mapView == null,
                        onAction: _send,
                        onOpenItems: (mode) => _openItems(me.uid, mode),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// El mapa dibujado, o null si todavía no carga o le faltan casillas. En
  /// ese caso se muestra el tablero de cuadritos para que se pueda jugar.
  Widget? _mapView(GameState game, String myId) {
    final map = ref.watch(boardMapProvider);
    final texture = ref.watch(pathTextureProvider).value;
    final board = ref.watch(boardProvider);
    if (map.hasError) debugPrint('Mapa: ${map.error}');
    final loaded = map.value;
    if (loaded == null || texture == null) return null;
    final missing = loaded.missingTiles(board.tiles.map((tile) => tile.id));
    if (missing.isNotEmpty) {
      debugPrint('Mapa: faltan las casillas $missing');
      return null;
    }
    return BoardMapView(
      map: loaded,
      board: board,
      pathTexture: texture,
      state: game,
      myId: myId,
      onChooseBranch: (branch) => _send(ChooseBranch(myId, branch)),
    );
  }
}

/// Parte de abajo: ronda, jugadores y el botón de lo que toca hacer.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.game,
    required this.myId,
    required this.isHost,
    required this.branchButtons,
    required this.onAction,
    required this.onOpenItems,
  });

  /// Alto del panel debajo del mapa.
  static const height = 230.0;

  final GameState game;
  final String myId;
  final bool isHost;

  /// Botones Seguir y Atajo, solo si no se ve el mapa dibujado (en el mapa
  /// se elige con las flechas).
  final bool branchButtons;
  final void Function(GameAction action) onAction;

  /// Abre la tienda del mapa o tu mochila.
  final void Function(ItemsMode mode) onOpenItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.boardPanel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ronda ${game.round} de ${game.totalRounds}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final (index, id) in game.turnOrder.indexed)
                  _PlayerRow(
                    player: game.players[id]!,
                    color: AppColors.players[index % AppColors.players.length],
                    hasTurn:
                        game.phase != GamePhase.minigame &&
                        game.phase != GamePhase.finished &&
                        id == game.currentPlayerId,
                  ),
              ],
            ),
          ),
          _actions(),
        ],
      ),
    );
  }

  Widget _actions() {
    final myTurn = game.currentPlayerId == myId;
    final current = game.currentPlayer.username;
    return switch (game.phase) {
      GamePhase.rolling when myTurn => Row(
        children: [
          Expanded(
            flex: 3,
            child: _Button(
              label: 'Lanzar dado',
              onPressed: () => onAction(RollDice(myId)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _Button(
              label: 'Mochila',
              onPressed: () => onOpenItems(ItemsMode.backpack),
            ),
          ),
        ],
      ),
      GamePhase.rolling => Text(
        '${_lastRoll()}Turno de $current',
        textAlign: TextAlign.center,
      ),
      GamePhase.choosingBranch when myTurn && !branchButtons => const Text(
        'Toca una flecha en el mapa para elegir el camino',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      GamePhase.choosingBranch when myTurn => Row(
        children: [
          Expanded(
            child: _Button(
              label: 'Seguir',
              onPressed: () => onAction(ChooseBranch(myId, 0)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Button(
              label: 'Atajo',
              onPressed: () => onAction(ChooseBranch(myId, 1)),
            ),
          ),
        ],
      ),
      GamePhase.choosingBranch => Text(
        '$current está eligiendo camino',
        textAlign: TextAlign.center,
      ),
      GamePhase.shopping when myTurn => Row(
        children: [
          Expanded(
            child: _Button(
              label: 'Tienda',
              onPressed: () => onOpenItems(ItemsMode.shop),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Button(
              label: 'Terminar',
              onPressed: () => onAction(LeaveShop(myId)),
            ),
          ),
        ],
      ),
      GamePhase.shopping => Text(
        '$current está comprando en la tienda',
        textAlign: TextAlign.center,
      ),
      // Provisional hasta tener minijuegos: el creador sortea un ganador.
      GamePhase.minigame when isHost => _Button(
        label: 'Simular minijuego',
        onPressed: () {
          final winner =
              game.turnOrder[Random().nextInt(game.turnOrder.length)];
          onAction(FinishMinigame([winner]));
        },
      ),
      GamePhase.minigame => const Text(
        'Esperando el minijuego...',
        textAlign: TextAlign.center,
      ),
      GamePhase.finished => Text(
        _winnerText(),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    };
  }

  /// "Último dado: 4 + 2 (dado extra) + 3 (impulso). "
  String _lastRoll() {
    if (game.lastRoll == 0) return '';
    final extra = game.lastExtraRoll > 0
        ? ' + ${game.lastExtraRoll} (dado extra)'
        : '';
    final boost = game.lastBoost > 0 ? ' + ${game.lastBoost} (impulso)' : '';
    return 'Último dado: ${game.lastRoll}$extra$boost. ';
  }

  /// Provisional: la pantalla de resultados llega en feature/results-xp.
  String _winnerText() {
    final result = const AwardCalculator().calculate(game);
    final names = [
      for (final id in result.winnerIds) game.players[id]!.username,
    ];
    return '¡Partida terminada! Ganó ${names.join(' y ')}';
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.color,
    required this.hasTurn,
  });

  final PlayerState player;
  final Color color;
  final bool hasTurn;

  /// Ítems en la mochila.
  int get _items => player.inventory.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(backgroundColor: color, radius: 10),
      title: Text(
        player.username,
        style: TextStyle(
          fontWeight: hasTurn ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.coin, size: 18),
          Text(' ${player.coins}   '),
          const Icon(Icons.diamond, color: AppColors.diamond, size: 18),
          Text(' ${player.diamonds}'),
          if (_items > 0) ...[
            const Text('   '),
            const Icon(Icons.backpack, color: AppColors.tileShop, size: 18),
            Text(' $_items'),
          ],
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: AppColors.authAccent,
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
