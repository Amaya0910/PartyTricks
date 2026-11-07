import 'dart:math';

import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Lo que recibe la pantalla de un minijuego.
abstract class MinigameWidget extends StatefulWidget {
  const MinigameWidget({
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
}

/// Minijuegos donde cada uno juega por su lado y manda su puntaje una sola
/// vez. Se encarga de la cuenta regresiva, de no mandarlo dos veces y de lo
/// que se ve al terminar.
///
/// Se usa así:
/// `with SingleTickerProviderStateMixin, MinigameClock, MinigameSolo`.
mixin MinigameSolo<T extends MinigameWidget> on State<T>, MinigameClock<T> {
  int? _sent;

  MinigameState get game => widget.minigame;
  MinigameRules get rules => widget.rules;
  bool get plays => game.players.contains(widget.myId);

  /// Lo que ya mandó (aquí o antes de reconectarse).
  int? get myScore => _sent ?? game.scores[widget.myId];

  /// ms desde que terminó la cuenta regresiva (negativo antes).
  int get playMs => elapsedMs - rules.introMs;

  /// Si se está jugando en este momento.
  bool get playing => plays && myScore == null && playMs >= 0;

  void sendScore(int score) {
    if (myScore != null) return;
    final value = score == MinigameRules.noScore
        ? score
        : score.clamp(0, rules.maxScore(game.type));
    setState(() => _sent = value);
    stopClock();
    widget.onPlay(value);
  }

  /// El cuerpo de la tarjeta: la cuenta regresiva, el juego ([arena]) o, al
  /// terminar, lo que le salió ([doneText]) mientras espera a los demás.
  /// [arena] recibe el contexto de adentro de la tarjeta.
  Widget soloBody({
    required WidgetBuilder arena,
    required String Function(int score) doneText,
    required IconData doneIcon,
  }) {
    if (!plays) return const MinigameSpectator();
    final score = myScore;
    if (score != null) {
      final failed = score == MinigameRules.noScore;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinigameFeedback(
                text: failed ? 'Se acabó el tiempo' : doneText(score),
                icon: failed ? Icons.hourglass_bottom_rounded : doneIcon,
                color: failed ? AppColors.minigameOut : null,
              ),
              const SizedBox(height: 14),
              MinigameWaiting(minigame: game),
            ],
          ),
          if (!failed)
            Positioned.fill(
              child: MinigameBurst(
                colors: [
                  game.type.accent,
                  AppColors.medalGold,
                  AppColors.white,
                ],
              ),
            ),
        ],
      );
    }
    if (playMs < 0) return MinigameIntro(leftMs: -playMs);
    return Builder(builder: arena);
  }
}

/// Minijuegos por vueltas: todos eligen en secreto, se revela lo que pasó y
/// sigue la próxima vuelta. Lleva el tiempo de cada parte y, si se acaba el
/// tiempo de elegir, avisa que este teléfono no eligió.
///
/// Se usa así:
/// `with SingleTickerProviderStateMixin, MinigameClock, MinigameRounds`.
mixin MinigameRounds<T extends MinigameWidget> on State<T>, MinigameClock<T> {
  late int _revealStartMs = -widget.rules.revealMs(game.type);
  int? _sentStage;

  MinigameState get game => widget.minigame;
  MinigameRules get rules => widget.rules;

  int get _revealMs => rules.revealMs(game.type);

  /// Si está en la cuenta regresiva del principio.
  bool get inIntro => game.stage == 0 && elapsedMs < rules.introMs;

  /// Si se está viendo lo que pasó en la vuelta anterior.
  bool get revealing =>
      game.stage > 0 && (game.ending || elapsedMs - _revealStartMs < _revealMs);

  /// ms desde que empezó a verse lo que pasó.
  int get revealClockMs => elapsedMs - _revealStartMs;

  /// ms que quedan para elegir.
  int get choiceLeftMs {
    final start = game.stage == 0 ? rules.introMs : _revealStartMs + _revealMs;
    return max(0, rules.choiceMs(game.type) - (elapsedMs - start));
  }

  /// Si este teléfono sigue en juego.
  bool get active => game.alive.contains(widget.myId);

  /// Si ya eligió en esta vuelta (aquí o antes de reconectarse).
  bool get hasPicked =>
      _sentStage == game.stage || game.scores.containsKey(widget.myId);

  /// Si puede elegir ahora.
  bool get choosing => active && !inIntro && !revealing && !hasPicked;

  /// Empezó a verse lo que pasó; [before] es como estaba antes.
  void onReveal(MinigameState before) {}

  void pick(int value) {
    if (hasPicked) return;
    setState(() => _sentStage = game.stage);
    widget.onPlay(MinigamePick.encode(game.stage, value));
  }

  @override
  void onClock() {
    super.onClock();
    if (choosing && choiceLeftMs <= 0) pick(MinigamePick.none);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (game.stage != oldWidget.minigame.stage) {
      _revealStartMs = elapsedMs;
      onReveal(oldWidget.minigame);
    }
  }
}

/// El escenario de un minijuego: un recuadro con relieve, como el de
/// Reacción, con un degradado de arriba hacia abajo.
class MinigameArena extends StatelessWidget {
  const MinigameArena({
    super.key,
    required this.colors,
    required this.child,
    this.height = 250,
    this.compactHeight = 210,
  });

  final List<Color> colors;
  final Widget child;
  final double height;

  /// Alto cuando el espacio es bajo.
  final double compactHeight;

  static const double _depth = 6;
  static const double _radius = 24;
  static const double _border = 4;

  @override
  Widget build(BuildContext context) {
    final compact = MinigameAccent.compactOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: _depth),
      child: SizedBox(
        width: double.infinity,
        height: compact ? compactHeight : height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            border: Border.all(color: AppColors.white, width: _border),
            boxShadow: [
              BoxShadow(
                color: minigameShade(colors.last, 0.35),
                offset: const Offset(0, _depth),
              ),
              const BoxShadow(
                color: AppColors.pillShadow,
                blurRadius: 10,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius - _border),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Barrita con el tiempo que queda: de 1 (recién empieza) a 0 (se acabó).
/// Cuando queda poco se pone roja.
class MinigameTimeBar extends StatelessWidget {
  const MinigameTimeBar({
    super.key,
    required this.left,
    this.color,
    this.width,
    this.height = 8,
    this.track = AppColors.minigameTrack,
  });

  final double left;

  /// Por defecto, el color del minijuego.
  final Color? color;

  /// Por defecto, todo lo que haya.
  final double? width;
  final double height;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final fill = left.clamp(0.0, 1.0);
    final color = this.color ?? MinigameAccent.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            FractionallySizedBox(
              widthFactor: fill,
              heightFactor: 1,
              child: ColoredBox(
                color: fill < 0.3 ? AppColors.minigameOut : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// De quién es el turno, con su color y una barrita del tiempo que le
/// queda.
class MinigameTurnBanner extends StatelessWidget {
  const MinigameTurnBanner({
    super.key,
    required this.text,
    required this.color,
    required this.left,
  });

  final String text;
  final Color color;

  /// De 1 (recién empieza) a 0 (se acabó).
  final double left;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: minigameTint(color, 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinigamePlayerDot(color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: minigameTextStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: minigameShade(color, 0.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MinigameTimeBar(left: left, color: color, width: 180),
        ],
      ),
    );
  }
}

/// Puntito con el color del jugador.
class MinigamePlayerDot extends StatelessWidget {
  const MinigamePlayerDot({super.key, required this.color, this.size = 14});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
      ),
    );
  }
}

/// Aviso que entra con un rebote: alguien quedó fuera, cambió la regla...
class MinigameAlert extends StatelessWidget {
  const MinigameAlert({
    super.key,
    required this.text,
    this.icon = Icons.flare_rounded,
    this.color = AppColors.minigameOut,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0.5, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: minigameShade(color, 0.35),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: minigameTextStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Número que da un saltito cada vez que cambia (puntos, racha...).
class MinigameCounter extends StatelessWidget {
  const MinigameCounter({
    super.key,
    required this.value,
    required this.icon,
    this.color,
    this.fontSize = 16,
  });

  final String value;
  final IconData icon;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 1.3, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: MinigamePill(
        text: value,
        icon: icon,
        color: color,
        fontSize: fontSize,
      ),
    );
  }
}

/// Texto con contorno oscuro, para que se lea sobre cualquier fondo.
class MinigameOutlinedText extends StatelessWidget {
  const MinigameOutlinedText(
    this.text, {
    super.key,
    required this.fontSize,
    this.color = AppColors.white,
    this.outline = AppColors.characterOutline,
    this.outlineWidth = 4,
  });

  final String text;
  final double fontSize;
  final Color color;
  final Color outline;
  final double outlineWidth;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: minigameTextStyle.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.05,
        color: color,
        shadows: minigameOutline(outline, outlineWidth / 2),
      ),
    );
  }
}

/// Texto que sube y se desvanece ("+10"). Se quita solo.
class MinigameFloat extends StatelessWidget {
  const MinigameFloat({
    super.key,
    required this.text,
    this.color = AppColors.white,
    this.fontSize = 24,
    this.rise = 46,
  });

  final String text;
  final Color color;
  final double fontSize;
  final double rise;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(
          opacity: 1 - t * t,
          child: Transform.translate(
            offset: Offset(0, -rise * t),
            child: Transform.scale(
              scale: 0.8 + 0.35 * sin(pi * t),
              child: child,
            ),
          ),
        ),
        child: MinigameOutlinedText(text, fontSize: fontSize, color: color),
      ),
    );
  }
}

/// Explosión de papelitos desde [center] (por defecto, el centro). Pasa una
/// sola vez: para repetirla, cambia su `key`.
class MinigameBurst extends StatelessWidget {
  const MinigameBurst({
    super.key,
    required this.colors,
    this.center,
    this.seed = 7,
    this.pieces = 22,
    this.reach = 130,
    this.duration = const Duration(milliseconds: 800),
  });

  final List<Color> colors;
  final Offset? center;
  final int seed;
  final int pieces;

  /// Hasta dónde llegan, en píxeles.
  final double reach;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        builder: (context, t, _) {
          if (t >= 1) return const SizedBox.shrink();
          return CustomPaint(
            size: Size.infinite,
            painter: _BurstPainter(
              t: t,
              colors: colors,
              center: center,
              seed: seed,
              pieces: pieces,
              reach: reach,
            ),
          );
        },
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.t,
    required this.colors,
    required this.center,
    required this.seed,
    required this.pieces,
    required this.reach,
  });

  final double t;
  final List<Color> colors;
  final Offset? center;
  final int seed;
  final int pieces;
  final double reach;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = center ?? size.center(Offset.zero);
    final sequence = MinigameSequence(seed);
    final eased = Curves.easeOutCubic.transform(t);
    final paint = Paint();
    for (var i = 0; i < pieces; i++) {
      final angle = sequence.next(0, 359) * pi / 180;
      final distance = reach * sequence.next(35, 100) / 100;
      final side = sequence.next(4, 9).toDouble();
      final spin = sequence.next(2, 8).toDouble();
      final fall = 70 * t * t;
      final position =
          origin +
          Offset(cos(angle), sin(angle)) * (distance * eased) +
          Offset(0, fall);
      paint.color = colors[i % colors.length].withValues(alpha: 1 - t * t * t);
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(spin * t)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: side,
              height: side * 0.65,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// Sacudida de pantalla: cuánto se mueve a los [ms] de empezar, en una que
/// dura [durationMs]. Después de eso no se mueve.
Offset minigameShake(int ms, {int durationMs = 420, double strength = 9}) {
  if (ms < 0 || ms >= durationMs) return Offset.zero;
  final left = 1 - ms / durationMs;
  return Offset(sin(ms / 17) * strength * left, cos(ms / 23) * strength * left);
}

/// Una ficha por jugador con su color, su nombre y [trailing] (vidas,
/// estrellas, listo...). Los que quedaron fuera se ven apagados.
class MinigameStandings extends StatelessWidget {
  const MinigameStandings({
    super.key,
    required this.game,
    required this.players,
    this.trailing,
  });

  final MinigameState game;
  final MinigamePlayers players;
  final Widget? Function(String id)? trailing;

  @override
  Widget build(BuildContext context) {
    final compact = MinigameAccent.compactOf(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final id in game.players)
          _Standing(
            name: players.nameOf(id),
            color: players.colorOf(id),
            out: game.out.contains(id),
            compact: compact,
            trailing: trailing?.call(id),
          ),
      ],
    );
  }
}

class _Standing extends StatelessWidget {
  const _Standing({
    required this.name,
    required this.color,
    required this.out,
    required this.compact,
    this.trailing,
  });

  final String name;
  final Color color;
  final bool out;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dot = out ? AppColors.minigameTrack : color;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: out ? 0.55 : 1,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: minigameTint(dot, 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: dot, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MinigamePlayerDot(color: dot, size: 12),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 74),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: minigameTextStyle.copyWith(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  decoration: out ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (trailing case final trailing?) ...[
              const SizedBox(width: 4),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
