import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/results_controller.dart';
import 'package:party_tricks/controllers/room_guard.dart';
import 'package:party_tricks/controllers/stats_controller.dart';
import 'package:party_tricks/screens/results_screen.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/map_providers.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/services/stats/match_time_tracker.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/board_view.dart';
import 'package:party_tricks/widgets/confirm_dialog.dart';
import 'package:party_tricks/widgets/dice_roll_overlay.dart';
import 'package:party_tricks/widgets/map_items_dialog.dart';
import 'package:party_tricks/widgets/map/board_map_view.dart';
import 'package:party_tricks/widgets/minigames/minigame_result_overlay.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Pantalla de la partida: el tablero, los jugadores y lo que toca hacer.
///
/// En el teléfono del anfitrión también corre el que aplica las acciones de
/// todos. Si el anfitrión se va, otro jugador toma su lugar ([RoomGuard]) y
/// su teléfono empieza a aplicarlas; [isHost] solo dice quién empieza.
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

  /// Presencia, cambio de anfitrión y turnos de los desconectados.
  RoomGuard? _guard;
  String? _myUid;

  /// Mide la partida para las estadísticas (tiempo jugando y en minijuegos).
  final _timeTracker = MatchTimeTracker();

  /// Para guardar la partida en las estadísticas una sola vez.
  bool _statsRecorded = false;

  /// Veces que lanzó cada jugador, para saber quién acaba de lanzar. Al
  /// entrar (o volver) a la partida no se anima la tirada anterior.
  Map<String, int>? _diceCounts;

  /// La última tirada que se anima sobre el mapa.
  DiceRoll? _roll;

  bool get _isHost => _stopHost != null;

  @override
  void initState() {
    super.initState();
    if (widget.isHost) _setHosting(true);
    ref.listenManual(
      roomIdentityProvider,
      (_, next) => _onIdentity(next.value?.uid),
      fireImmediately: true,
    );
    ref.listenManual(roomProvider(widget.roomId), (_, next) {
      final room = next.value;
      _guard?.update(room: room);
      final uid = _myUid;
      if (room != null && uid != null) _setHosting(room.hostUid == uid);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _stopHost?.call();
    _guard?.dispose();
    super.dispose();
  }

  void _onIdentity(String? uid) {
    if (uid == null || _myUid != null) return;
    _myUid = uid;
    final rooms = ref.read(roomServiceProvider);
    // Para volver a la partida si se cierra la app.
    rooms.setActiveGame(uid, widget.roomId).catchError((Object error) {
      debugPrint('No se pudo guardar la partida en curso: $error');
    });
    _guard = RoomGuard(
      roomId: widget.roomId,
      uid: uid,
      rooms: rooms,
      presence: ref.read(presenceServiceProvider),
      policy: ref.read(disconnectionPolicyProvider),
      onSkipTurn: (playerId) => ref
          .read(gameServiceProvider)
          .sendAction(widget.roomId, SkipTurn(playerId)),
      onMinigameTimeout: (action) =>
          ref.read(gameServiceProvider).sendAction(widget.roomId, action),
    )..start();
    final room = ref.read(roomProvider(widget.roomId)).value;
    _guard!.update(
      room: room,
      game: ref.read(gameProvider(widget.roomId)).value,
    );
    if (room != null) _setHosting(room.hostUid == uid);
  }

  /// Empieza o deja de aplicar las acciones de todos. Las que llegaron
  /// mientras no había anfitrión siguen en la fila y se aplican al empezar.
  void _setHosting(bool host) {
    if (host == _isHost) return;
    if (host) {
      _stopHost = ref.read(gameServiceProvider).runHost(widget.roomId);
    } else {
      _stopHost!.call();
      _stopHost = null;
    }
    if (mounted) setState(() {});
  }

  /// Salir de la sala: deja de ser su partida en curso. Si era el último en
  /// la sala, la sala se borra.
  Future<void> _leave() async {
    final uid = _myUid;
    if (uid != null) {
      final rooms = ref.read(roomServiceProvider);
      try {
        await rooms.setActiveGame(uid, null);
        await rooms.leave(roomId: widget.roomId, uid: uid);
      } catch (error) {
        debugPrint('No se pudo salir de la sala: $error');
      }
    }
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// A mitad de partida se pregunta antes de salir.
  Future<void> _confirmLeave() async {
    final leave = await ConfirmDialog.show(
      context,
      title: 'Salir',
      message:
          'Si sales, la partida sigue sin ti y no ganas XP ni premios. '
          'Tus turnos se saltan.',
      confirmLabel: 'Salir de la partida',
    );
    if (leave) await _leave();
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

  /// Al terminar la partida cada jugador guarda sus estadísticas, su XP y
  /// lo que pasa a su cuenta; el anfitrión además guarda el resultado en el
  /// registro de partidas.
  void _onGameChanged(GameState? game) {
    if (game == null) return;
    _watchDice(game);
    _timeTracker.onPhase(game.phase);
    if (game.phase != GamePhase.finished || _statsRecorded) return;
    _statsRecorded = true;
    final room = ref.read(roomProvider(widget.roomId)).value;
    final isPublic = room?.isPublic ?? false;
    ref
        .read(statsControllerProvider)
        .recordFinishedMatch(
          roomId: widget.roomId,
          game: game,
          tracker: _timeTracker,
          isHost: _isHost,
          isPublic: isPublic,
        );
    final hostUid = room?.hostUid ?? ref.read(roomIdentityProvider).value?.uid;
    if (_isHost && hostUid != null) {
      ref
          .read(resultsControllerProvider)
          .saveFinishedMatch(
            roomId: widget.roomId,
            hostUid: hostUid,
            game: game,
            isPublic: isPublic,
          );
    }
  }

  /// Si alguien acaba de lanzar, muestra su dado. Solo es visual: el
  /// número ya viene en la partida.
  void _watchDice(GameState game) {
    final counts = _diceCountsOf(game);
    final before = _diceCounts;
    _diceCounts = counts;
    if (before == null) return;
    for (final (index, id) in game.turnOrder.indexed) {
      if ((counts[id] ?? 0) <= (before[id] ?? 0)) continue;
      setState(() {
        _roll = DiceRoll(
          serial: (_roll?.serial ?? 0) + 1,
          username: game.players[id]!.username,
          color: AppColors.players[index % AppColors.players.length],
          value: game.lastRoll,
          extra: game.lastExtraRoll,
          boost: game.lastBoost,
        );
      });
      return;
    }
  }

  static Map<String, int> _diceCountsOf(GameState game) => {
    for (final player in game.players.values) player.id: player.diceRolled,
  };

  @override
  Widget build(BuildContext context) {
    ref.listen(gameProvider(widget.roomId), (_, next) {
      _guard?.update(game: next.value);
      _onGameChanged(next.value);
    });
    // Se escucha la sala para tenerla cargada al terminar (si es pública y
    // quién es el anfitrión); si no, Riverpod la pausa y llega vacía.
    ref.watch(roomProvider(widget.roomId));
    final game = ref.watch(gameProvider(widget.roomId)).value;
    final me = ref.watch(roomIdentityProvider).value;
    if (game != null) _diceCounts ??= _diceCountsOf(game);
    if (game != null && me != null && game.phase == GamePhase.finished) {
      return ResultsScreen(game: game, myId: me.uid, onExit: _leave);
    }
    final mapView = game == null || me == null ? null : _mapView(game, me.uid);
    final players = game == null ? null : _minigamePlayers(game);
    final minigame = game?.minigame;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.screenBackground,
        body: SafeArea(
          child: game == null || me == null
              ? const Center(child: Text('Preparando la partida...'))
              : Column(
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (game.phase == GamePhase.minigame &&
                              minigame != null)
                            MinigameView(
                              minigame: minigame,
                              myId: me.uid,
                              players: players!,
                              rules: ref
                                  .watch(gameEngineProvider)
                                  .minigameRules,
                              onPlay: (score) => _send(
                                MinigameMove(me.uid, minigame.round, score),
                              ),
                            )
                          else
                            mapView ??
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: BoardView(
                                    board: ref.watch(boardProvider),
                                    state: game,
                                  ),
                                ),
                          DiceRollOverlay(roll: _roll),
                          MinigameResultOverlay(
                            result: game.lastMinigame,
                            players: players!,
                            coins: ref.watch(gameEngineProvider).minigameCoins,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: _Panel.height,
                      child: _Panel(
                        game: game,
                        myId: me.uid,
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

  /// Nombre y color de cada jugador, para los minijuegos.
  MinigamePlayers _minigamePlayers(GameState game) {
    return MinigamePlayers(
      names: {for (final p in game.players.values) p.id: p.username},
      colors: {
        for (final (index, id) in game.turnOrder.indexed)
          id: AppColors.players[index % AppColors.players.length],
      },
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
    required this.branchButtons,
    required this.onAction,
    required this.onOpenItems,
  });

  /// Alto del panel debajo del mapa.
  static const height = 230.0;

  final GameState game;
  final String myId;

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
      // El minijuego se juega arriba, en lugar del mapa.
      GamePhase.minigame => Text(
        switch (game.minigame) {
          final minigame? => 'Minijuego: ${minigame.type.title}',
          null => 'Esperando el minijuego...',
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      // Al terminar se muestra ResultsScreen en vez del tablero.
      GamePhase.finished => const SizedBox.shrink(),
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
