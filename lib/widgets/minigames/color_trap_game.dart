import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Color Tramposo: sale el nombre de un color escrito con otro color y hay
/// que tocar el color de la tinta. Al final la regla se voltea y vale lo que
/// dice la palabra. Más rápido y con racha, más puntos.
class ColorTrapGame extends MinigameWidget {
  const ColorTrapGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<ColorTrapGame> createState() => _ColorTrapGameState();
}

class _ColorTrapGameState extends State<ColorTrapGame>
    with SingleTickerProviderStateMixin, MinigameClock, MinigameSolo {
  /// Los colores del juego: los mismos de los jugadores.
  static const List<String> _names = [
    'ROJO',
    'AZUL',
    'VERDE',
    'AMARILLO',
    'MORADO',
    'NARANJA',
  ];

  /// Pausa con el aviso de que cambió la regla.
  static const int _flipPauseMs = 1300;
  static const int _wrongMs = 320;

  late final List<ColorTrapRound> _rounds = colorTrapScript(
    game.seed,
    rounds: rules.colorTrapRounds,
    flipFrom: rules.colorTrapFlipFrom,
    colors: _names.length,
  );

  int _round = 0;
  int _roundStartMs = 0;
  int _points = 0;
  int _streak = 0;
  int _gained = 0;
  int _wrongAtMs = -100000;

  ColorTrapRound get _current => _rounds[_round];

  /// ms de la palabra actual (negativo durante el aviso).
  int get _wordMs => playMs - _roundStartMs;
  bool get _flipPause => _wordMs < 0;
  bool get _wrongShown => playMs - _wrongAtMs < _wrongMs;

  @override
  void onClock() {
    if (playing && _wordMs >= rules.colorTrapWordMs) _miss();
  }

  void _next() {
    if (_round + 1 == rules.colorTrapRounds) {
      sendScore(_points);
      return;
    }
    _round++;
    _roundStartMs =
        playMs + (_round == rules.colorTrapFlipFrom ? _flipPauseMs : 0);
  }

  void _miss() {
    HapticFeedback.mediumImpact();
    setState(() {
      _streak = 0;
      _gained = 0;
      _wrongAtMs = playMs;
      _next();
    });
  }

  void _answer(int color) {
    if (!playing || _flipPause) return;
    if (color != _current.answer) {
      _miss();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _streak++;
      _gained = colorTrapPoints(
        spentMs: _wordMs,
        limitMs: rules.colorTrapWordMs,
        streak: _streak,
      );
      _points += _gained;
      _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.colorTrap,
      instructions:
          'Toca el color de la TINTA, no el que dice la palabra. '
          '¡Atento, que la regla cambia!',
      child: soloBody(
        arena: _arena,
        doneText: (score) => '¡$score puntos!',
        doneIcon: Icons.palette_rounded,
      ),
    );
  }

  Widget _arena(BuildContext context) {
    final round = _current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            MinigameCounter(value: '$_points', icon: Icons.star_rounded),
            const Spacer(),
            if (_streak >= 2)
              MinigameCounter(
                value: 'x$_streak',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.coin,
              ),
            const SizedBox(width: 8),
            MinigamePill(
              text: '${_round + 1}/${rules.colorTrapRounds}',
              fontSize: 14,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Transform.translate(
          offset: _wrongShown
              ? minigameShake(playMs - _wrongAtMs, durationMs: _wrongMs)
              : Offset.zero,
          child: _flipPause ? _flipNotice() : _word(context, round),
        ),
        const SizedBox(height: 10),
        _Choices(
          round: _round,
          choices: round.choices,
          names: _names,
          onChoose: _flipPause ? null : _answer,
        ),
      ],
    );
  }

  Widget _flipNotice() {
    return MinigameArena(
      height: 168,
      compactHeight: 136,
      colors: const [AppColors.minigameColorTrap, AppColors.minigameOut],
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinigameOutlinedText('¡TRAMPA!', fontSize: 36),
              SizedBox(height: 6),
              MinigameOutlinedText('Ahora vale la PALABRA', fontSize: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget _word(BuildContext context, ColorTrapRound round) {
    final compact = MinigameAccent.compactOf(context);
    final flipped = round.flipped;
    return MinigameArena(
      height: 168,
      compactHeight: 136,
      colors: flipped
          ? const [AppColors.colorTrapNight, AppColors.characterOutline]
          : const [AppColors.white, AppColors.minigameSoft],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: MinigameTimeBar(left: 1 - _wordMs / rules.colorTrapWordMs),
          ),
          const SizedBox(height: 6),
          _RuleTag(flipped: flipped),
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_round),
                tween: Tween(begin: 0.7, end: 1),
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: MinigameOutlinedText(
                        _names[round.word],
                        fontSize: compact ? 44 : 54,
                        color: AppColors.players[round.ink],
                        outline: flipped
                            ? AppColors.white
                            : AppColors.characterOutline,
                        outlineWidth: 3,
                      ),
                    ),
                    if (_gained > 0)
                      Positioned(
                        top: -16,
                        right: -46,
                        child: MinigameFloat(
                          key: ValueKey('puntos-$_round'),
                          text: '+$_gained',
                          color: AppColors.medalGold,
                          fontSize: 20,
                          rise: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recuerda qué regla vale ahora.
class _RuleTag extends StatelessWidget {
  const _RuleTag({required this.flipped});

  final bool flipped;

  @override
  Widget build(BuildContext context) {
    return Text(
      flipped ? 'Vale la PALABRA' : 'Vale la TINTA',
      style: minigameTextStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: flipped ? AppColors.white : AppColors.authHint,
      ),
    );
  }
}

/// Los cuatro botones de colores, de dos en dos.
class _Choices extends StatelessWidget {
  const _Choices({
    required this.round,
    required this.choices,
    required this.names,
    required this.onChoose,
  });

  final int round;
  final List<int> choices;
  final List<String> names;
  final void Function(int color)? onChoose;

  @override
  Widget build(BuildContext context) {
    Widget button(int color) {
      final onChoose = this.onChoose;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          // Cada palabra tiene botones nuevos: si no, el color cambiaría de
          // a poco y se vería uno con el nombre de otro.
          child: MinigameButton(
            key: ValueKey('$round/$color'),
            label: names[color],
            color: AppColors.players[color],
            minWidth: 0,
            fontSize: 17,
            height: 50,
            onPressed: onChoose == null ? null : () => onChoose(color),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [button(choices[0]), button(choices[1])]),
        Row(children: [button(choices[2]), button(choices[3])]),
      ],
    );
  }
}
