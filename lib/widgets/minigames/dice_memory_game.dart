import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/map/map_assets.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Memoria de Dados: salen unos dados uno por uno y hay que repetirlos en el
/// mismo orden. Cada vez que aciertas, la fila crece. Gana quien llegue más
/// lejos.
class DiceMemoryGame extends MinigameWidget {
  const DiceMemoryGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<DiceMemoryGame> createState() => _DiceMemoryGameState();
}

/// En qué va la fila actual.
enum _Stage { showing, repeating, passed, failed }

class _DiceMemoryGameState extends State<DiceMemoryGame>
    with SingleTickerProviderStateMixin, MinigameClock, MinigameSolo {
  static const _passedMs = 650;
  static const _failedMs = 1300;

  late final List<int> _faces = diceMemoryFaces(game.seed, rules.diceMemoryMax);
  late int _length = rules.diceMemoryStart;
  _Stage _stage = _Stage.showing;

  /// Cuándo empezó la parte actual, en ms de juego.
  int _stageStartMs = 0;

  /// Cuántos dados lleva bien en esta fila.
  int _progress = 0;

  /// La fila más larga que repitió bien.
  int _best = 0;

  /// La cara que tocó mal.
  int? _wrong;

  int get _stageMs => playMs - _stageStartMs;

  /// Cuánto se ve cada dado: menos mientras más larga es la fila.
  int get _dieMs => max(340, 640 - (_length - rules.diceMemoryStart) * 45);

  void _enter(_Stage stage) {
    _stage = stage;
    _stageStartMs = playMs;
  }

  @override
  void onClock() {
    if (!playing) return;
    if (playMs >= rules.diceMemoryLimitMs) {
      sendScore(_best);
      return;
    }
    switch (_stage) {
      case _Stage.showing when _stageMs >= _length * _dieMs + 250:
        setState(() => _enter(_Stage.repeating));
      case _Stage.passed when _stageMs >= _passedMs:
        if (_length == rules.diceMemoryMax) {
          sendScore(_best);
        } else {
          setState(() {
            _length++;
            _progress = 0;
            _enter(_Stage.showing);
          });
        }
      case _Stage.failed when _stageMs >= _failedMs:
        sendScore(_best);
      default:
        break;
    }
  }

  void _press(int face) {
    if (_stage != _Stage.repeating) return;
    setState(() {
      if (face != _faces[_progress]) {
        HapticFeedback.heavyImpact();
        _wrong = face;
        _enter(_Stage.failed);
        return;
      }
      HapticFeedback.selectionClick();
      _progress++;
      if (_progress == _length) {
        _best = _length;
        _enter(_Stage.passed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.diceMemory,
      instructions:
          'Mira los dados y repítelos en el mismo orden. Cada vez son más.',
      child: soloBody(
        arena: _arena,
        doneText: (score) => score == 0
            ? 'No repetiste ninguna fila'
            : 'Llegaste a $score dados',
        doneIcon: Icons.psychology_rounded,
      ),
    );
  }

  Widget _arena(BuildContext context) {
    final shake = _stage == _Stage.failed
        ? minigameShake(_stageMs)
        : Offset.zero;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            MinigamePill(
              text: 'Fila de $_length',
              icon: Icons.casino_rounded,
              fontSize: 14,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MinigameTimeBar(
                left: 1 - playMs / rules.diceMemoryLimitMs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Transform.translate(
          offset: shake,
          child: MinigameArena(
            height: 266,
            compactHeight: 226,
            colors: const [AppColors.blueLight, AppColors.blueStrong],
            child: switch (_stage) {
              _Stage.showing => _Showing(
                face: _shownFace,
                index: _stageMs ~/ _dieMs,
                total: _length,
              ),
              _ => _Repeating(
                faces: _faces.sublist(0, _length),
                progress: _progress,
                stage: _stage,
                wrong: _wrong,
                onPress: _press,
              ),
            },
          ),
        ),
      ],
    );
  }

  /// La cara que se ve ahora, o null entre un dado y otro.
  int? get _shownFace {
    final index = _stageMs ~/ _dieMs;
    if (index >= _length) return null;
    // Un parpadeo entre dados, para que se note cuando cambia.
    return _stageMs % _dieMs < _dieMs * 0.78 ? _faces[index] : null;
  }
}

/// La cara de un dado con el arte del juego.
class _Die extends StatelessWidget {
  const _Die({required this.face, required this.size});

  final int face;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: Image.asset(
        MapAssets.dice(face),
        width: size,
        height: size,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          color: AppColors.white,
          child: Text(
            '$face',
            style: minigameTextStyle.copyWith(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Un dado grande que entra con un rebote, y abajo cuántos van.
class _Showing extends StatelessWidget {
  const _Showing({
    required this.face,
    required this.index,
    required this.total,
  });

  final int? face;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final compact = MinigameAccent.compactOf(context);
    final size = compact ? 104.0 : 128.0;
    final face = this.face;
    return Column(
      children: [
        const SizedBox(height: 12),
        const MinigameOutlinedText(
          '¡Memoriza!',
          fontSize: 24,
          outline: AppColors.headerBorder,
        ),
        Expanded(
          child: Center(
            child: face == null
                ? const SizedBox.shrink()
                : TweenAnimationBuilder<double>(
                    key: ValueKey(index),
                    tween: Tween(begin: 0.55, end: 1),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: _Die(face: face, size: size),
                  ),
          ),
        ),
        _Dots(total: total, done: min(index + 1, total)),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done ? AppColors.white : AppColors.headerBorder,
            ),
          ),
      ],
    );
  }
}

/// Los dados que ya acertó arriba y los seis botones abajo.
class _Repeating extends StatelessWidget {
  const _Repeating({
    required this.faces,
    required this.progress,
    required this.stage,
    required this.wrong,
    required this.onPress,
  });

  final List<int> faces;
  final int progress;
  final _Stage stage;
  final int? wrong;
  final void Function(int face) onPress;

  @override
  Widget build(BuildContext context) {
    final compact = MinigameAccent.compactOf(context);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(
            height: compact ? 54 : 64,
            child: Center(child: _top()),
          ),
          const Spacer(),
          for (final row in const [
            [1, 2, 3],
            [4, 5, 6],
          ])
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final face in row)
                    _DieButton(
                      face: face,
                      size: compact ? 60 : 70,
                      wrong: wrong == face,
                      enabled: stage == _Stage.repeating,
                      onPress: () => onPress(face),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _top() {
    if (stage == _Stage.passed) {
      return const _Banner(text: '¡Bien! Uno más');
    }
    if (stage == _Stage.failed) {
      return _Banner(text: 'Era este:', face: faces[progress]);
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < faces.length; i++)
          i < progress
              ? _Die(face: faces[i], size: 26)
              : Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.headerBorder,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: i == progress
                          ? AppColors.white
                          : AppColors.blueLight,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '?',
                    style: minigameTextStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.white,
                    ),
                  ),
                ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.face});

  final String text;
  final int? face;

  @override
  Widget build(BuildContext context) {
    final face = this.face;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: MinigameOutlinedText(
              text,
              fontSize: 24,
              outline: AppColors.headerBorder,
            ),
          ),
          if (face != null) ...[
            const SizedBox(width: 10),
            _Die(face: face, size: 46),
          ],
        ],
      ),
    );
  }
}

/// Un dado para tocar: se hunde al apoyar el dedo.
class _DieButton extends StatefulWidget {
  const _DieButton({
    required this.face,
    required this.size,
    required this.wrong,
    required this.enabled,
    required this.onPress,
  });

  final int face;
  final double size;
  final bool wrong;
  final bool enabled;
  final VoidCallback onPress;

  @override
  State<_DieButton> createState() => _DieButtonState();
}

class _DieButtonState extends State<_DieButton> {
  bool _down = false;

  /// El aviso de soltar llega aunque el dado ya no esté en la pantalla.
  void _setDown(bool down) {
    if (mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (!widget.enabled) return;
        _setDown(true);
        widget.onPress();
      },
      onPointerUp: (_) => _setDown(false),
      onPointerCancel: (_) => _setDown(false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedScale(
          scale: _down ? 0.86 : 1,
          duration: const Duration(milliseconds: 70),
          child: Container(
            decoration: widget.wrong
                ? BoxDecoration(
                    color: AppColors.minigameOut,
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            padding: const EdgeInsets.all(2),
            child: _Die(face: widget.face, size: widget.size),
          ),
        ),
      ),
    );
  }
}
