import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Cables Rojos: por turnos, cada uno corta un cable de la bomba. Uno de
/// ellos la hace explotar y quien lo corte queda fuera. Con los que quedan
/// sale otra bomba. Gana el último.
class WiresGame extends MinigameWidget {
  const WiresGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<WiresGame> createState() => _WiresGameState();
}

class _WiresGameState extends State<WiresGame>
    with SingleTickerProviderStateMixin, MinigameClock {
  final _random = Random();

  /// Cuándo empezó el turno actual, en ms del reloj.
  late int _turnStartMs = widget.rules.introMs;

  /// El paso en el que este teléfono ya cortó y qué cable, para no mandar
  /// dos veces mientras llega la respuesta.
  int? _sentStep;
  int _sentWire = 0;

  /// La explosión que se está viendo: la bomba como quedó, el cable y quién
  /// lo cortó.
  MinigameState? _explodedBomb;
  int _boomMs = 0;
  String? _victim;

  /// Último cable que se cortó sin explotar, para decir "¡Uf!".
  int _safeCuts = 0;

  MinigameRules get _rules => widget.rules;
  MinigameState get _game => widget.minigame;

  bool get _inIntro => _game.step == 0 && elapsedMs < _rules.introMs;
  bool get _booming =>
      _explodedBomb != null &&
      (_game.ending || elapsedMs - _boomMs < _rules.wiresBoomMs);
  int get _turnLeftMs => _rules.wiresTurnMs - (elapsedMs - _turnStartMs);
  bool get _mine => _game.balloonPlayer == widget.myId;
  bool get _canCut =>
      _mine &&
      !_game.ending &&
      !_inIntro &&
      !_booming &&
      _sentStep != _game.step;

  @override
  void didUpdateWidget(WiresGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.minigame;
    if (_game.step == before.step) return;
    if (_game.out.length > before.out.length) {
      HapticFeedback.heavyImpact();
      _explodedBomb = before;
      _boomMs = elapsedMs;
      _victim = _game.out.last;
      _turnStartMs = elapsedMs + _rules.wiresBoomMs;
    } else {
      HapticFeedback.selectionClick();
      _safeCuts++;
      _turnStartMs = elapsedMs;
    }
  }

  @override
  void onClock() {
    if (!_canCut || _turnLeftMs > 0) return;
    final left = [
      for (var wire = 0; wire < _game.wires; wire++)
        if (!_game.cut.contains(wire)) wire,
    ];
    _cut(left[_random.nextInt(left.length)]);
  }

  void _cut(int wire) {
    if (!_canCut || _game.cut.contains(wire)) return;
    setState(() {
      _sentStep = _game.step;
      _sentWire = wire;
    });
    widget.onPlay(wire);
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.wires,
      instructions:
          'En tu turno, corta un cable. Uno hace explotar la bomba: si te '
          'toca, quedas fuera.',
      child: _inIntro
          ? MinigameIntro(leftMs: _rules.introMs - elapsedMs)
          : _body(),
    );
  }

  Widget _body() {
    final players = widget.players;
    final booming = _booming;
    final current = _game.balloonPlayer;
    final left = _turnLeftMs.clamp(0, _rules.wiresTurnMs - 1);
    final victim = _victim;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booming && victim != null)
          MinigameAlert(text: '¡Le explotó a ${players.nameOf(victim)}!')
        else
          MinigameTurnBanner(
            text: _mine
                ? 'Tu turno (${left ~/ 1000 + 1} s)'
                : 'Turno de ${players.nameOf(current)}',
            color: players.colorOf(current),
            left: left / _rules.wiresTurnMs,
          ),
        const SizedBox(height: 10),
        Transform.translate(
          offset: booming
              ? minigameShake(
                  elapsedMs - _boomMs,
                  durationMs: 700,
                  strength: 12,
                )
              : Offset.zero,
          child: _Bomb(
            bomb: booming ? _explodedBomb! : _game,
            pending: _sentStep == _game.step ? _sentWire : null,
            seconds: left ~/ 1000 + 1,
            boomMs: booming ? elapsedMs - _boomMs : null,
            boomWire: _game.cursed,
            safeCuts: _safeCuts,
            clockMs: elapsedMs,
            onCut: _canCut ? _cut : null,
          ),
        ),
        const SizedBox(height: 8),
        MinigameStandings(game: _game, players: players),
      ],
    );
  }
}

/// La bomba: la pantalla con los segundos arriba y los cables debajo. Cada
/// cable es una columna que se puede tocar.
class _Bomb extends StatelessWidget {
  const _Bomb({
    required this.bomb,
    required this.pending,
    required this.seconds,
    required this.boomMs,
    required this.boomWire,
    required this.safeCuts,
    required this.clockMs,
    required this.onCut,
  });

  final MinigameState bomb;

  /// Cable que este teléfono acaba de cortar y aún no confirma el anfitrión.
  final int? pending;
  final int seconds;

  /// ms desde la explosión, o null si no hay.
  final int? boomMs;
  final int boomWire;
  final int safeCuts;
  final int clockMs;
  final void Function(int wire)? onCut;

  @override
  Widget build(BuildContext context) {
    final boomMs = this.boomMs;
    final onCut = this.onCut;
    return MinigameArena(
      height: 258,
      compactHeight: 214,
      colors: const [AppColors.bombCase, AppColors.characterOutline],
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              _Display(
                seconds: seconds,
                armed: onCut != null,
                clockMs: clockMs,
              ),
              Expanded(
                child: Row(
                  children: [
                    for (var wire = 0; wire < bomb.wires; wire++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: onCut == null ? null : (_) => onCut(wire),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _Wire(
                                color:
                                    AppColors.wireColors[wire %
                                        AppColors.wireColors.length],
                                cut: _isCut(wire),
                              ),
                              if (onCut != null && !_isCut(wire))
                                _Scissors(clockMs: clockMs + wire * 140),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const _Rail(),
            ],
          ),
          if (safeCuts > 0 && boomMs == null)
            Align(
              alignment: const Alignment(0, 0.2),
              child: MinigameFloat(key: ValueKey(safeCuts), text: '¡Uf!'),
            ),
          if (boomMs != null) _Explosion(ms: boomMs),
        ],
      ),
    );
  }

  bool _isCut(int wire) =>
      bomb.cut.contains(wire) ||
      wire == pending ||
      (boomMs != null && wire == boomWire);
}

/// Pantalla roja con los segundos que quedan.
class _Display extends StatelessWidget {
  const _Display({
    required this.seconds,
    required this.armed,
    required this.clockMs,
  });

  final int seconds;

  /// Si es tu turno: el reloj parpadea.
  final bool armed;
  final int clockMs;

  @override
  Widget build(BuildContext context) {
    final on = !armed || clockMs % 600 < 400;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.characterOutline,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.safeRim, width: 2),
      ),
      child: Text(
        '00:${seconds.toString().padLeft(2, '0')}',
        style: minigameTextStyle.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: on ? AppColors.bombDisplay : AppColors.bombDisplayOff,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Tijeras que respiran sobre cada cable cuando te toca cortar.
class _Scissors extends StatelessWidget {
  const _Scissors({required this.clockMs});

  final int clockMs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.scale(
        scale: 1 + sin(clockMs / 170) * 0.12,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.characterOutline,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.content_cut_rounded,
            size: 16,
            color: AppColors.bombCase,
          ),
        ),
      ),
    );
  }
}

/// Barra de abajo donde se conectan los cables.
class _Rail extends StatelessWidget {
  const _Rail();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.safeRim,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Un cable. Al cortarlo, sus dos puntas se separan con una chispa.
class _Wire extends StatelessWidget {
  const _Wire({required this.color, required this.cut});

  final Color color;
  final bool cut;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: cut ? 1 : 0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, gap, _) => CustomPaint(
        size: Size.infinite,
        painter: _WirePainter(color: color, gap: gap),
      ),
    );
  }
}

class _WirePainter extends CustomPainter {
  _WirePainter({required this.color, required this.gap});

  final Color color;

  /// De 0 (entero) a 1 (cortado).
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final h = size.height;
    final middle = h * 0.5;
    final open = h * 0.16 * gap;
    final bend = size.width * 0.32 * (1 - gap * 0.4);

    void cable(Path path) {
      canvas
        ..drawPath(
          path,
          Paint()
            ..color = AppColors.characterOutline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 11
            ..strokeCap = StrokeCap.round,
        )
        ..drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round,
        );
    }

    if (gap <= 0) {
      cable(
        Path()
          ..moveTo(x, 0)
          ..cubicTo(x + bend, h * 0.34, x - bend, h * 0.66, x, h),
      );
      return;
    }
    cable(
      Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(x + bend, h * 0.22, x + 4 * gap, middle - open),
    );
    cable(
      Path()
        ..moveTo(x, h)
        ..quadraticBezierTo(x - bend, h * 0.78, x - 4 * gap, middle + open),
    );
    final copper = Paint()..color = AppColors.medalGold;
    canvas
      ..drawCircle(Offset(x + 4 * gap, middle - open), 3.5, copper)
      ..drawCircle(Offset(x - 4 * gap, middle + open), 3.5, copper);
  }

  @override
  bool shouldRepaint(_WirePainter old) => old.gap != gap || old.color != color;
}

/// El fogonazo: blanco al principio, luego naranja, con papelitos y BOOM.
class _Explosion extends StatelessWidget {
  const _Explosion({required this.ms});

  final int ms;

  @override
  Widget build(BuildContext context) {
    final flash = (1 - ms / 900).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Color.lerp(
            AppColors.coin,
            AppColors.white,
            flash,
          )!.withValues(alpha: 0.2 + 0.75 * flash),
        ),
        const MinigameBurst(
          reach: 190,
          pieces: 40,
          duration: Duration(milliseconds: 1100),
          colors: [
            AppColors.coin,
            AppColors.minigameOut,
            AppColors.medalGold,
            AppColors.white,
          ],
        ),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.2, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: const MinigameOutlinedText(
              '¡BOOM!',
              fontSize: 64,
              color: AppColors.coin,
              outlineWidth: 7,
            ),
          ),
        ),
      ],
    );
  }
}
