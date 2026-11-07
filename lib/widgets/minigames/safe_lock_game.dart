import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Cofre Fuerte: una aguja gira alrededor de la cerradura y hay que detenerla
/// sobre la marca dorada. Son tres cerrojos, cada uno más rápido y con la
/// marca más pequeña. Mientras más al centro, más puntos.
class SafeLockGame extends MinigameWidget {
  const SafeLockGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<SafeLockGame> createState() => _SafeLockGameState();
}

class _SafeLockGameState extends State<SafeLockGame>
    with SingleTickerProviderStateMixin, MinigameClock, MinigameSolo {
  /// Cuánto se ve lo que salió antes del siguiente cerrojo.
  static const int _resultMs = 1000;

  /// Cuánto se ve el cofre al terminar.
  static const int _chestMs = 1500;

  late final List<SafeLockSetup> _locks = safeLockScript(
    game.seed,
    rules.safeLocks,
  );

  int _lock = 0;
  int _lockStartMs = 0;
  final List<int> _results = [];

  /// Dónde quedó la aguja en este cerrojo, si ya se detuvo.
  double? _stoppedAt;
  int _stoppedMs = 0;
  int _finishedMs = 0;
  bool _finished = false;

  SafeLockSetup get _current => _locks[_lock];
  double get _needle => _stoppedAt ?? _current.needleAt(playMs - _lockStartMs);

  int get _total => _results.fold(0, (sum, points) => sum + points);
  int get _opened => _results.where((points) => points > 0).length;

  @override
  void onClock() {
    if (!playing) return;
    if (_finished) {
      if (playMs - _finishedMs >= _chestMs) sendScore(_total);
      return;
    }
    final stopped = _stoppedAt != null;
    if (stopped && playMs - _stoppedMs >= _resultMs) {
      setState(_nextLock);
    } else if (!stopped && playMs - _lockStartMs >= rules.safeLockTurnMs) {
      _stop();
    }
  }

  void _nextLock() {
    if (_lock + 1 == _locks.length) {
      _finished = true;
      _finishedMs = playMs;
      return;
    }
    _lock++;
    _lockStartMs = playMs;
    _stoppedAt = null;
  }

  void _stop() {
    if (!playing || _stoppedAt != null || _finished) return;
    final needle = _needle;
    final points = safeLockPoints(
      safeLockDistance(needle, _current.markDeg),
      _current.widthDeg,
    );
    points > 0 ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _stoppedAt = needle;
      _stoppedMs = playMs;
      _results.add(points);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.safeLock,
      instructions:
          'Detén la aguja sobre la marca dorada. Cada cerrojo es más difícil.',
      child: soloBody(
        arena: _arena,
        doneText: (score) => '¡$score puntos en la caja fuerte!',
        doneIcon: Icons.lock_open_rounded,
      ),
    );
  }

  Widget _arena(BuildContext context) {
    if (_finished) return _Treasure(opened: _opened, total: _total);
    final stopped = _stoppedAt != null;
    final last = stopped ? _results.last : 0;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _stop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MinigameArena(
            height: 296,
            compactHeight: 258,
            colors: const [AppColors.safeSteel, AppColors.safeSteelDark],
            child: Column(
              children: [
                const SizedBox(height: 10),
                _Padlocks(
                  total: _locks.length,
                  current: _lock,
                  results: _results,
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CustomPaint(
                            painter: _DialPainter(
                              needleDeg: _needle,
                              markDeg: _current.markDeg,
                              widthDeg: _current.widthDeg,
                              result: stopped ? (last > 0) : null,
                            ),
                          ),
                        ),
                      ),
                      if (stopped)
                        _ResultText(
                          key: ValueKey(_lock),
                          points: last,
                          perfect: last > 100,
                        ),
                    ],
                  ),
                ),
                MinigameTimeBar(
                  left: stopped
                      ? 1
                      : 1 - (playMs - _lockStartMs) / rules.safeLockTurnMs,
                  width: 180,
                  color: AppColors.medalGold,
                  track: AppColors.safeSteelDark,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),
          MinigameButton(
            label: '¡Alto!',
            icon: Icons.pan_tool_rounded,
            minWidth: 180,
            onPressed: stopped ? null : _stop,
          ),
        ],
      ),
    );
  }
}

/// Un candado por cerrojo: abierto, roto o por abrir.
class _Padlocks extends StatelessWidget {
  const _Padlocks({
    required this.total,
    required this.current,
    required this.results,
  });

  final int total;
  final int current;
  final List<int> results;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _padlock(i),
          ),
      ],
    );
  }

  Widget _padlock(int index) {
    if (index < results.length) {
      final opened = results[index] > 0;
      return Icon(
        opened ? Icons.lock_open_rounded : Icons.lock_rounded,
        color: opened ? AppColors.reactionGo : AppColors.minigameOut,
        size: 26,
      );
    }
    return Icon(
      Icons.lock_rounded,
      color: index == current ? AppColors.medalGold : AppColors.safeRim,
      size: 26,
    );
  }
}

class _ResultText extends StatelessWidget {
  const _ResultText({super.key, required this.points, required this.perfect});

  final int points;
  final bool perfect;

  @override
  Widget build(BuildContext context) {
    final text = switch (points) {
      0 => '¡Fallaste!',
      _ when perfect => '¡Perfecto!\n+$points',
      _ => '+$points',
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: MinigameOutlinedText(
        text,
        fontSize: 26,
        color: points == 0 ? AppColors.minigameOut : AppColors.medalGold,
      ),
    );
  }
}

/// La cerradura: marcas, la zona dorada y la aguja.
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.needleDeg,
    required this.markDeg,
    required this.widthDeg,
    required this.result,
  });

  final double needleDeg;
  final double markDeg;
  final double widthDeg;

  /// Si la acertó, o null mientras gira.
  final bool? result;

  static const _ticks = 36;

  /// Convierte grados (0 arriba) a los que usa el lienzo (0 a la derecha).
  double _radians(double degrees) => (degrees - 90) * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Aro exterior con sus tornillos.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            AppColors.safeRim,
            AppColors.white,
            AppColors.safeRim,
            AppColors.safeSteel,
            AppColors.safeRim,
          ],
        ).createShader(rect),
    );
    final bolt = Paint()..color = AppColors.safeSteelDark;
    for (var i = 0; i < 8; i++) {
      final angle = 2 * pi * i / 8 + pi / 8;
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * (radius * 0.93),
        radius * 0.028,
        bolt,
      );
    }

    // Cara de la cerradura.
    final face = radius * 0.86;
    canvas.drawCircle(
      center,
      face,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [AppColors.safeSteel, AppColors.safeSteelDark],
        ).createShader(Rect.fromCircle(center: center, radius: face)),
    );

    final tick = Paint()
      ..color = AppColors.safeRim
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _ticks; i++) {
      final angle = 2 * pi * i / _ticks;
      final direction = Offset(cos(angle), sin(angle));
      final big = i % 3 == 0;
      tick.strokeWidth = big ? 3 : 1.5;
      canvas.drawLine(
        center + direction * (face - 3),
        center + direction * (face - (big ? 14 : 9)),
        tick,
      );
    }

    // La marca, en su color según cómo salió.
    final markColor = switch (result) {
      true => AppColors.reactionGo,
      false => AppColors.minigameOut,
      null => AppColors.medalGold,
    };
    final arc = face - 22;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arc),
      _radians(markDeg - widthDeg / 2),
      widthDeg * pi / 180,
      false,
      Paint()
        ..color = markColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.butt,
    );

    // La aguja.
    final angle = _radians(needleDeg);
    final tip = center + Offset(cos(angle), sin(angle)) * (face - 6);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppColors.characterOutline
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppColors.minigameOut
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      radius * 0.17,
      Paint()..color = AppColors.safeRim,
    );
    canvas.drawCircle(
      center,
      radius * 0.1,
      Paint()..color = AppColors.safeSteelDark,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.needleDeg != needleDeg ||
      old.markDeg != markDeg ||
      old.widthDeg != widthDeg ||
      old.result != result;
}

/// Lo que había adentro: mientras más cerrojos abriste, mejor cofre.
class _Treasure extends StatelessWidget {
  const _Treasure({required this.opened, required this.total});

  final int opened;
  final int total;

  @override
  Widget build(BuildContext context) {
    final chest = switch (opened) {
      0 => null,
      1 => ChestType.basic,
      2 => ChestType.party,
      _ => ChestType.diamond,
    };
    return MinigameArena(
      height: 296,
      compactHeight: 258,
      colors: const [AppColors.safeSteel, AppColors.safeSteelDark],
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 620),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (chest == null)
                  const Icon(
                    Icons.lock_rounded,
                    size: 110,
                    color: AppColors.safeRim,
                  )
                else
                  Image.asset(
                    chest.asset,
                    height: 136,
                    cacheWidth: 300,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.inventory_2_rounded,
                      size: 110,
                      color: AppColors.medalGold,
                    ),
                  ),
                const SizedBox(height: 10),
                MinigameOutlinedText(
                  chest == null ? 'Sigue cerrado' : '¡Abriste $opened de 3!',
                  fontSize: 24,
                  color: chest == null ? AppColors.white : AppColors.medalGold,
                ),
                const SizedBox(height: 4),
                MinigameOutlinedText('$total puntos', fontSize: 19),
              ],
            ),
          ),
          if (chest != null)
            const Positioned.fill(
              child: MinigameBurst(
                reach: 170,
                pieces: 34,
                colors: [
                  AppColors.medalGold,
                  AppColors.white,
                  AppColors.diamond,
                ],
              ),
            ),
        ],
      ),
    );
  }
}
