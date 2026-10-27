import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/board_view.dart';

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

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider(widget.roomId)).value;
    final me = ref.watch(roomIdentityProvider).value;
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
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: BoardView(
                        board: ref.watch(boardProvider),
                        state: game,
                      ),
                    ),
                    Expanded(
                      child: _Panel(
                        game: game,
                        myId: me.uid,
                        isHost: widget.isHost,
                        onAction: _send,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Parte de abajo: ronda, jugadores y el botón de lo que toca hacer.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.game,
    required this.myId,
    required this.isHost,
    required this.onAction,
  });

  final GameState game;
  final String myId;
  final bool isHost;
  final void Function(GameAction action) onAction;

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
    final lastRoll = game.lastRoll > 0 ? 'Último dado: ${game.lastRoll}. ' : '';
    return switch (game.phase) {
      GamePhase.rolling when myTurn => _Button(
        label: 'Lanzar dado',
        onPressed: () => onAction(RollDice(myId)),
      ),
      GamePhase.rolling => Text(
        '${lastRoll}Turno de $current',
        textAlign: TextAlign.center,
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
