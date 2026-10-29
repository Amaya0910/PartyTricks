import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Resultado del minijuego sobre el mapa: quién ganó, lo que hizo cada uno
/// y, si hubo empate, el desempate con el dado. Se quita solo y no tapa los
/// toques.
///
/// Solo aparece cuando termina un minijuego nuevo: al entrar (o volver) a
/// la partida no se repite el anterior.
class MinigameResultOverlay extends StatefulWidget {
  const MinigameResultOverlay({
    super.key,
    required this.result,
    required this.players,
    required this.coins,
  });

  final MinigameResult? result;
  final MinigamePlayers players;

  /// Monedas que gana cada ganador.
  final int coins;

  /// Cuánto se ve.
  static const duration = Duration(seconds: 5);

  @override
  State<MinigameResultOverlay> createState() => _MinigameResultOverlayState();
}

class _MinigameResultOverlayState extends State<MinigameResultOverlay>
    with SingleTickerProviderStateMixin {
  /// La última parte se desvanece.
  static const _fadeStart = 0.85;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: MinigameResultOverlay.duration,
        )..addStatusListener((_) {
          if (mounted) setState(() {});
        });
  }

  @override
  void didUpdateWidget(MinigameResultOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final result = widget.result;
    final old = oldWidget.result;
    if (result != null &&
        (old == null || old.round != result.round || old.type != result.type)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (result == null || !_controller.isAnimating) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final opacity = t < _fadeStart
              ? 1.0
              : 1 - (t - _fadeStart) / (1 - _fadeStart);
          return Opacity(opacity: opacity.clamp(0, 1).toDouble(), child: child);
        },
        child: ColoredBox(
          color: AppColors.diceScrim,
          child: Center(
            child: SingleChildScrollView(
              child: MinigameResultCard(
                result: result,
                players: widget.players,
                coins: widget.coins,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La tarjeta con el resultado.
class MinigameResultCard extends StatelessWidget {
  const MinigameResultCard({
    super.key,
    required this.result,
    required this.players,
    required this.coins,
  });

  final MinigameResult result;
  final MinigamePlayers players;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final winners = result.winnerIds.map(players.nameOf).toList();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.minigamePanel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.type.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            winners.isEmpty ? 'Nadie ganó' : 'Ganó ${winners.join(' y ')}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.minigameWinner,
            ),
          ),
          if (winners.isNotEmpty) Text('+$coins monedas'),
          const SizedBox(height: 12),
          if (result.type == MinigameType.stopwatch)
            Text(
              'Objetivo: ${formatSeconds(result.targetMs)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          for (final line in _lines()) Text(line, textAlign: TextAlign.center),
          if (result.tiebreak.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Empate: se desempató con el dado',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final MapEntry(key: id, value: rolls)
                in result.tiebreak.entries)
              Text('${players.nameOf(id)}: ${rolls.join(', ')}'),
          ],
        ],
      ),
    );
  }

  /// Lo que hizo cada uno, según el minijuego.
  List<String> _lines() {
    if (result.type == MinigameType.balloon) {
      return [
        for (final id in result.out) '${players.nameOf(id)}: reventó el globo',
      ];
    }
    return [
      for (final MapEntry(key: id, value: score) in result.scores.entries)
        '${players.nameOf(id)}: ${_score(score)}',
    ];
  }

  String _score(int score) {
    if (score == MinigameRules.noScore) return 'no cuenta';
    return result.type == MinigameType.stopwatch
        ? formatSeconds(score)
        : '$score ms';
  }
}
