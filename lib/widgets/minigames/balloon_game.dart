import 'dart:math';

import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Globo Bomba: por turnos, cada uno infla el globo 1, 2 o 3 veces. Nadie
/// sabe cuánto aguanta; al que se le revienta, sale. Gana el último.
class BalloonGame extends StatefulWidget {
  const BalloonGame({
    super.key,
    required this.minigame,
    required this.myId,
    required this.players,
    required this.rules,
    required this.onPlay,
  });

  final MinigameState minigame;
  final String myId;
  final MinigamePlayers players;
  final MinigameRules rules;
  final void Function(int score) onPlay;

  @override
  State<BalloonGame> createState() => _BalloonGameState();
}

class _BalloonGameState extends State<BalloonGame>
    with SingleTickerProviderStateMixin, MinigameClock {
  /// Infladas con las que el globo se ve al doble de tamaño.
  static const _pumpsToDouble = 35;

  /// Cuándo empezó el turno actual, en ms del reloj.
  int _turnStartMs = 0;

  /// El paso en el que este teléfono ya infló, para no mandar dos veces
  /// mientras llega la respuesta.
  int? _sentStep;

  /// Quién reventó el último globo, para avisarlo un momento.
  String? _popped;

  MinigameRules get _rules => widget.rules;
  MinigameState get _game => widget.minigame;

  @override
  void didUpdateWidget(BalloonGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_game.step != oldWidget.minigame.step) {
      _turnStartMs = elapsedMs;
      if (_game.out.length > oldWidget.minigame.out.length) {
        _popped = _game.out.last;
      }
    }
  }

  /// ms que le quedan al turno; el primero empieza después de la
  /// explicación.
  int get _turnLeftMs {
    final start = _game.step == 0 ? _rules.introMs : _turnStartMs;
    return _rules.balloonTurnMs - (elapsedMs - start);
  }

  void _inflate(int times) {
    if (_sentStep == _game.step) return;
    setState(() => _sentStep = _game.step);
    widget.onPlay(times);
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.balloon,
      instructions:
          'En tu turno, infla 1, 2 o 3 veces. Nadie sabe cuánto aguanta: '
          'si te revienta, quedas fuera.',
      child: _body(),
    );
  }

  Widget _body() {
    if (_game.step == 0 && elapsedMs < _rules.introMs) {
      return MinigameIntro(leftMs: _rules.introMs - elapsedMs);
    }
    final current = _game.balloonPlayer;
    final myTurn = current == widget.myId && _sentStep != _game.step;
    final players = widget.players;
    final popped = _popped;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (popped != null)
          Text(
            '¡Reventó el globo de ${players.nameOf(popped)}!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.minigameOut,
            ),
          ),
        _Balloon(
          scale: 1 + _game.pumps / _pumpsToDouble,
          color: players.colorOf(current),
        ),
        Text('Infladas: ${_game.pumps}'),
        const SizedBox(height: 8),
        Text(
          current == widget.myId
              ? 'Tu turno (${max(0, _turnLeftMs) ~/ 1000 + 1} s)'
              : 'Turno de ${players.nameOf(current)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (myTurn)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var times = 1; times <= _rules.maxPumps; times++)
                MinigameButton(
                  label: '+$times',
                  onPressed: () => _inflate(times),
                ),
            ],
          ),
        if (_game.out.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Fuera: ${_game.out.map(players.nameOf).join(', ')}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.minigameOut),
          ),
        ],
      ],
    );
  }
}

/// El globo, más grande mientras más inflado, con el color de quien infla.
class _Balloon extends StatelessWidget {
  const _Balloon({required this.scale, required this.color});

  final double scale;
  final Color color;

  static const _base = 70.0;

  @override
  Widget build(BuildContext context) {
    final size = _base * scale.clamp(1, 2.2);
    return SizedBox(
      height: _base * 2.3,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          width: size,
          height: size * 1.15,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.balloon, color, 0.3),
            borderRadius: BorderRadius.all(
              Radius.elliptical(size, size * 1.15),
            ),
            border: Border.all(color: AppColors.characterOutline, width: 3),
          ),
        ),
      ),
    );
  }
}
