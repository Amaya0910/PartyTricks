import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Pulso Perfecto: el corazón late unas veces y se detiene. Hay que seguir
/// tocando con ese mismo ritmo, sin nada que lo marque. Gana quien menos se
/// desvía.
class RhythmGame extends MinigameWidget {
  const RhythmGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<RhythmGame> createState() => _RhythmGameState();
}

class _RhythmGameState extends State<RhythmGame>
    with SingleTickerProviderStateMixin, MinigameClock, MinigameSolo {
  /// Desvíos con los que un toque cuenta como perfecto, bueno o regular.
  static const _perfectMs = 35;
  static const _goodMs = 80;
  static const _okMs = 150;

  late final int _beatMs = rhythmBeatMs(
    game.seed,
    min: rules.minBeatMs,
    max: rules.maxBeatMs,
  );

  final List<int> _taps = [];
  List<int> _errors = const [];
  int _lastBeat = -1;

  /// Cuándo debía ser el primer toque.
  int get _firstBeatMs => rules.rhythmDemoBeats * _beatMs;

  /// Se puede tocar desde medio pulso antes, para no castigar al que se
  /// adelanta un poquito en el primer toque.
  bool get _listening => playMs < _firstBeatMs - _beatMs ~/ 2;

  @override
  void onClock() {
    if (!playing) return;
    if (playMs >= rules.rhythmLimitMs) {
      sendScore(MinigameRules.noScore);
      return;
    }
    if (playMs < _firstBeatMs) {
      final beat = playMs ~/ _beatMs;
      if (beat != _lastBeat) {
        _lastBeat = beat;
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _tap() {
    if (!playing || _listening) return;
    HapticFeedback.lightImpact();
    setState(() {
      _taps.add(playMs);
      _errors = rhythmErrors(_taps, beatMs: _beatMs, firstBeatMs: _firstBeatMs);
    });
    if (_taps.length == rules.rhythmTaps) sendScore(rhythmAverage(_errors));
  }

  /// ms desde el último pulso que se ve o toque que se hizo.
  int get _sincePulse {
    if (_taps.isNotEmpty) return playMs - _taps.last;
    final listened = playMs < _firstBeatMs;
    return listened ? playMs % _beatMs : 100000;
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.rhythm,
      instructions:
          'Mira el ritmo del corazón. Cuando se detenga, sigue tocando '
          'igual ${rules.rhythmTaps} veces.',
      child: soloBody(
        arena: _arena,
        doneText: (score) => 'Te desviaste $score ms',
        doneIcon: Icons.favorite_rounded,
      ),
    );
  }

  Widget _arena(BuildContext context) {
    final listening = playMs < _firstBeatMs;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _tap(),
      child: MinigameArena(
        height: 280,
        compactHeight: 236,
        colors: [
          minigameTint(AppColors.minigameRhythm, 0.75),
          AppColors.minigameRhythmDark,
        ],
        child: Column(
          children: [
            const SizedBox(height: 12),
            _Message(
              key: ValueKey(_taps.length),
              text: listening ? 'Mira el ritmo...' : _tapMessage,
            ),
            Expanded(
              child: _Heart(sincePulseMs: _sincePulse, beatMs: _beatMs),
            ),
            _Beads(
              total: listening ? rules.rhythmDemoBeats : rules.rhythmTaps,
              done: listening ? playMs ~/ _beatMs + 1 : _taps.length,
              errors: listening ? const [] : _errors,
              colorOf: _colorOf,
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  String get _tapMessage {
    if (_errors.isEmpty) return '¡Ahora tú! Toca';
    final error = _errors.last;
    if (error <= _perfectMs) return '¡Perfecto!';
    if (error <= _goodMs) return '¡Muy bien!';
    if (error <= _okMs) return 'Casi...';
    return '¡Fuera de ritmo!';
  }

  Color _colorOf(int error) {
    if (error <= _goodMs) return AppColors.reactionGo;
    if (error <= _okMs) return AppColors.medalGold;
    return AppColors.minigameOut;
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: MinigameOutlinedText(
        text,
        fontSize: 24,
        outline: AppColors.minigameRhythmDark,
      ),
    );
  }
}

/// El corazón: late con cada pulso y deja anillos que se abren.
class _Heart extends StatelessWidget {
  const _Heart({required this.sincePulseMs, required this.beatMs});

  /// ms desde el último latido.
  final int sincePulseMs;
  final int beatMs;

  static const double _size = 112;
  static const double _compactSize = 88;

  @override
  Widget build(BuildContext context) {
    final size = MinigameAccent.compactOf(context) ? _compactSize : _size;
    // De 1 (acaba de latir) a 0 (en reposo).
    final beat = max(0.0, 1 - sincePulseMs / (beatMs * 0.75));
    final eased = Curves.easeOut.transform(beat);
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final delay in const [0.0, 0.3])
          if (beat > delay)
            Opacity(
              opacity: (beat - delay).clamp(0.0, 1.0) * 0.5,
              child: Container(
                width: size * (2.2 - (beat - delay) * 1.1),
                height: size * (2.2 - (beat - delay) * 1.1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 4),
                ),
              ),
            ),
        Transform.scale(
          scale: 1 + 0.32 * eased,
          child: Icon(
            Icons.favorite_rounded,
            size: size,
            color: AppColors.white,
            shadows: const [
              Shadow(color: AppColors.minigameRhythmDark, offset: Offset(0, 5)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Una cuenta por pulso. Las de los toques se pintan según qué tan bien
/// salieron.
class _Beads extends StatelessWidget {
  const _Beads({
    required this.total,
    required this.done,
    required this.errors,
    required this.colorOf,
  });

  final int total;
  final int done;
  final List<int> errors;
  final Color Function(int error) colorOf;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < errors.length
                    ? colorOf(errors[i])
                    : i < done
                    ? AppColors.white
                    : AppColors.minigameRhythmDark.withValues(alpha: 0.35),
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
