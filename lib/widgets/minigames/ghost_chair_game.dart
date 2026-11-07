import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// La Silla Fantasma: todos eligen una silla en secreto y luego llega el
/// fantasma a una de ellas. Los que estén ahí pierden una vida y quien se
/// queda sin vidas sale. Gana el último.
class GhostChairGame extends MinigameWidget {
  const GhostChairGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<GhostChairGame> createState() => _GhostChairGameState();
}

class _GhostChairGameState extends State<GhostChairGame>
    with SingleTickerProviderStateMixin, MinigameClock, MinigameRounds {
  /// Cuándo sale el fantasma y cuándo se detiene, desde que empieza a verse.
  static const int _ghostFromMs = 300;
  static const int _ghostLandsMs = 2700;

  /// Cuántas pasadas da por las sillas antes de detenerse.
  static const int _laps = 2;

  /// La silla que eligió este teléfono en esta vuelta.
  int? _mySeat;
  bool _landed = false;
  List<String> _hit = const [];
  List<String> _justOut = const [];

  bool get _ghostDone => revealing && revealClockMs >= _ghostLandsMs;

  /// La silla elegida (aquí o antes de reconectarse).
  int? get _seat => _mySeat ?? game.scores[widget.myId];

  @override
  void onReveal(MinigameState before) {
    _mySeat = null;
    _landed = false;
    _hit = [
      for (final entry in game.picks.entries)
        if (entry.value == game.cursed) entry.key,
    ];
    _justOut = [
      for (final id in game.out)
        if (!before.out.contains(id)) id,
    ];
  }

  @override
  void onClock() {
    super.onClock();
    if (_ghostDone && !_landed) {
      _landed = true;
      HapticFeedback.heavyImpact();
    }
  }

  void _sit(int chair) {
    if (!choosing) return;
    _mySeat = chair;
    pick(chair);
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.ghostChair,
      instructions:
          'Elige una silla y cruza los dedos: el fantasma llega a una. Tienes '
          '${rules.chairLives} vidas.',
      child: inIntro
          ? MinigameIntro(leftMs: rules.introMs - elapsedMs)
          : _body(),
    );
  }

  Widget _body() {
    final revealing = this.revealing;
    final landed = _ghostDone;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 44, child: Center(child: _top(landed))),
        const SizedBox(height: 6),
        Transform.translate(
          offset: landed
              ? minigameShake(revealClockMs - _ghostLandsMs, strength: 10)
              : Offset.zero,
          child: MinigameArena(
            height: 272,
            compactHeight: 232,
            colors: const [AppColors.ghostNight, AppColors.ghostFloor],
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(painter: _RoomPainter()),
                  Row(
                    children: [
                      for (var chair = 0; chair < rules.chairs; chair++)
                        Expanded(
                          child: _Seat(
                            chair: chair,
                            selected: !revealing && _seat == chair,
                            sitters: revealing ? _sittersOf(chair) : const [],
                            cursed: landed && chair == game.cursed,
                            enabled: choosing,
                            onTap: () => _sit(chair),
                          ),
                        ),
                    ],
                  ),
                  if (revealing && revealClockMs >= _ghostFromMs)
                    _ghost(box.biggest),
                  if (landed)
                    Positioned.fill(
                      child: MinigameBurst(
                        center: Offset(
                          box.maxWidth * (game.cursed + 0.5) / rules.chairs,
                          box.maxHeight * 0.55,
                        ),
                        colors: const [
                          AppColors.ghostGlow,
                          AppColors.white,
                          AppColors.minigameGhostChair,
                        ],
                        reach: 120,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        MinigameStandings(
          game: _visibleGame(landed),
          players: widget.players,
          trailing: (id) => _hearts(id, landed),
        ),
      ],
    );
  }

  /// Quienes acaban de salir siguen en juego hasta que llega el fantasma.
  MinigameState _visibleGame(bool landed) {
    if (landed || _justOut.isEmpty) return game;
    return game.copyWith(
      out: [
        for (final id in game.out)
          if (!_justOut.contains(id)) id,
      ],
    );
  }

  Widget _hearts(String id, bool landed) {
    var lives = game.points[id] ?? 0;
    // La vida se pierde cuando llega el fantasma, no antes.
    if (revealing && !landed && _hit.contains(id)) lives++;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rules.chairLives; i++)
          Icon(
            Icons.favorite_rounded,
            size: 13,
            color: i < lives ? AppColors.minigameOut : AppColors.minigameTrack,
          ),
        if (!revealing && game.scores.containsKey(id))
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColors.reactionGo,
          ),
      ],
    );
  }

  List<Color> _sittersOf(int chair) => [
    for (final entry in game.picks.entries)
      if (entry.value == chair) widget.players.colorOf(entry.key),
  ];

  Widget _top(bool landed) {
    final revealing = this.revealing;
    if (revealing && landed) {
      final names = _hit.map(widget.players.nameOf).join(' y ');
      return _hit.isEmpty
          ? const MinigameAlert(
              text: '¡Silla vacía! Nadie pierde',
              icon: Icons.sentiment_very_satisfied_rounded,
              color: AppColors.reactionGo,
            )
          : MinigameAlert(
              text: 'Atrapó a $names',
              icon: Icons.nights_stay_rounded,
              color: AppColors.minigameGhostChair,
            );
    }
    if (revealing) return const _Label(text: 'Ya viene el fantasma...');
    if (!active) return const _Label(text: 'Estás fuera: mira cómo acaban');
    if (hasPicked) return const _Label(text: 'Esperando a los demás...');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Label(text: '¿En qué silla te sientas?'),
        const SizedBox(height: 4),
        MinigameTimeBar(
          left: choiceLeftMs / rules.chairChoiceMs,
          height: 6,
          width: 200,
        ),
      ],
    );
  }

  /// El fantasma pasa por las sillas, cada vez más lento, y se detiene en la
  /// que le tocó.
  Widget _ghost(Size area) {
    const size = 92.0;
    final last = rules.chairs - 1;
    final t = ((revealClockMs - _ghostFromMs) / (_ghostLandsMs - _ghostFromMs))
        .clamp(0.0, 1.0);
    // Recorre las sillas de ida y vuelta y termina justo en la elegida.
    final travel =
        Curves.easeOutCubic.transform(t) * (2 * last * _laps + game.cursed);
    final wrapped = travel % (2 * last);
    final position = wrapped <= last ? wrapped : 2 * last - wrapped;
    final landed = t >= 1;
    final x = area.width * (position + 0.5) / rules.chairs;
    final bob = sin(elapsedMs / 150) * (landed ? 3 : 8);
    final y = landed ? area.height * 0.34 : area.height * 0.12;
    return Positioned(
      left: x - size / 2,
      top: y + bob,
      width: size,
      height: size * 1.1,
      child: Transform.scale(
        scale: landed ? 1.15 : 1,
        child: CustomPaint(painter: _GhostPainter(scared: landed)),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: minigameTextStyle.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.minigameGhostChair,
        ),
      ),
    );
  }
}

/// Una silla para tocar, con los que se sentaron encima.
class _Seat extends StatelessWidget {
  const _Seat({
    required this.chair,
    required this.selected,
    required this.sitters,
    required this.cursed,
    required this.enabled,
    required this.onTap,
  });

  final int chair;
  final bool selected;
  final List<Color> sitters;
  final bool cursed;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = cursed
        ? AppColors.ghostGlow
        : AppColors.ghostChairs[chair % AppColors.ghostChairs.length];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => onTap() : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 24,
            child: Wrap(
              spacing: 2,
              alignment: WrapAlignment.center,
              children: [
                for (final sitter in sitters)
                  MinigamePlayerDot(color: sitter, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 2),
          AnimatedScale(
            scale: selected ? 1.14 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: SizedBox(
              width: 76,
              height: 96,
              child: CustomPaint(
                painter: _ChairPainter(color: color, selected: selected),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Silla de madera con el respaldo alto. La elegida brilla.
class _ChairPainter extends CustomPainter {
  _ChairPainter({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = Paint()
      ..color = selected ? AppColors.pillBackground : AppColors.characterOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 3.5 : 2.5
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    final dark = Paint()..color = minigameShade(color, 0.35);

    void piece(RRect shape, Paint paint) {
      canvas
        ..drawRRect(shape, paint)
        ..drawRRect(shape, outline);
    }

    RRect bar(double l, double t, double r, double b, [double radius = 4]) =>
        RRect.fromLTRBR(l * w, t * h, r * w, b * h, Radius.circular(radius));

    // Patas.
    piece(bar(0.16, 0.6, 0.28, 1), dark);
    piece(bar(0.72, 0.6, 0.84, 1), dark);
    // Respaldo.
    piece(bar(0.16, 0.02, 0.84, 0.58, 12), fill);
    piece(bar(0.3, 0.14, 0.7, 0.46, 8), dark);
    // Asiento.
    piece(bar(0.08, 0.54, 0.92, 0.68, 6), fill);
  }

  @override
  bool shouldRepaint(_ChairPainter old) =>
      old.color != color || old.selected != selected;
}

/// La habitación: la luna, las estrellas y el piso.
class _RoomPainter extends CustomPainter {
  const _RoomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final moon = Offset(size.width * 0.84, size.height * 0.16);
    canvas
      ..drawCircle(moon, 30, Paint()..color = AppColors.minigameShine)
      ..drawCircle(moon, 20, Paint()..color = AppColors.pillBackground);
    final star = Paint()..color = AppColors.minigameShine;
    for (final (x, y) in const [
      (0.1, 0.12),
      (0.26, 0.24),
      (0.42, 0.08),
      (0.6, 0.2),
      (0.94, 0.42),
    ]) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), 2, star);
    }
    canvas.drawRect(
      Rect.fromLTRB(0, size.height - 22, size.width, size.height),
      Paint()..color = AppColors.ghostFloorEdge,
    );
  }

  @override
  bool shouldRepaint(_RoomPainter oldDelegate) => false;
}

/// El fantasma: redondito, con la cola ondulada y cara de susto.
class _GhostPainter extends CustomPainter {
  _GhostPainter({required this.scared});

  /// Cuando llega a la silla abre más la boca.
  final bool scared;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Path()
      ..moveTo(0.1 * w, 0.92 * h)
      ..lineTo(0.1 * w, 0.42 * h)
      ..cubicTo(0.1 * w, 0.02 * h, 0.9 * w, 0.02 * h, 0.9 * w, 0.42 * h)
      ..lineTo(0.9 * w, 0.92 * h)
      ..quadraticBezierTo(0.78 * w, 0.8 * h, 0.66 * w, 0.92 * h)
      ..quadraticBezierTo(0.56 * w, 1.02 * h, 0.5 * w, 0.92 * h)
      ..quadraticBezierTo(0.42 * w, 0.8 * h, 0.34 * w, 0.92 * h)
      ..quadraticBezierTo(0.22 * w, 1.02 * h, 0.1 * w, 0.92 * h)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..color = AppColors.ghostGlow.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(body, Paint()..color = AppColors.white);
    canvas.drawPath(
      body,
      Paint()
        ..color = AppColors.minigameGhostChair
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final ink = Paint()..color = AppColors.characterOutline;
    for (final x in const [0.36, 0.64]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x * w, 0.4 * h),
          width: 0.13 * w,
          height: 0.19 * h,
        ),
        ink,
      );
      canvas.drawCircle(
        Offset((x + 0.02) * w, 0.36 * h),
        0.025 * w,
        Paint()..color = AppColors.white,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.5 * w, 0.62 * h),
        width: (scared ? 0.26 : 0.12) * w,
        height: (scared ? 0.22 : 0.08) * h,
      ),
      ink,
    );
    final blush = Paint()..color = AppColors.characterBlush;
    canvas
      ..drawCircle(Offset(0.22 * w, 0.52 * h), 0.06 * w, blush)
      ..drawCircle(Offset(0.78 * w, 0.52 * h), 0.06 * w, blush);
  }

  @override
  bool shouldRepaint(_GhostPainter old) => old.scared != scared;
}
