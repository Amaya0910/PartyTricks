import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/map/map_assets.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Cazamonedas: caen monedas, diamantes y bombas. Las monedas dan 1 punto,
/// los diamantes 5 y las bombas quitan 3. Todos ven caer lo mismo.
class CoinRainGame extends MinigameWidget {
  const CoinRainGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<CoinRainGame> createState() => _CoinRainGameState();
}

/// Lo que dejó un toque: el "+1" que sube y sus chispas.
class _Hit {
  const _Hit({
    required this.id,
    required this.position,
    required this.kind,
    required this.atMs,
  });

  final int id;
  final Offset position;
  final FallingKind kind;
  final int atMs;
}

class _CoinRainGameState extends State<CoinRainGame>
    with SingleTickerProviderStateMixin, MinigameClock, MinigameSolo {
  static const double _size = 50;

  /// Margen para que no haga falta tocar la pieza con exactitud.
  static const double _reach = 38;
  static const int _hitLifeMs = 800;
  static const int _flashMs = 260;

  late final List<FallingItem> _items = coinRainScript(
    game.seed,
    rules.coinRainMs,
  );

  final Set<int> _taken = {};
  final List<_Hit> _hits = [];
  Size _area = Size.zero;
  int _points = 0;
  int _lastBombMs = -100000;

  @override
  void onClock() {
    if (!playing) return;
    if (playMs >= rules.coinRainMs) sendScore(_points);
    _hits.removeWhere((hit) => playMs - hit.atMs > _hitLifeMs);
  }

  Offset _positionOf(FallingItem item) {
    final progress = (playMs - item.startMs) / item.fallMs;
    final sway = sin((playMs + item.id * 400) / 260) * 7;
    return Offset(
      item.x * _area.width + sway,
      -_size + progress * (_area.height + _size * 1.4),
    );
  }

  bool _isFalling(FallingItem item) {
    final age = playMs - item.startMs;
    return age >= 0 && age < item.fallMs && !_taken.contains(item.id);
  }

  void _tap(Offset point) {
    if (!playing) return;
    FallingItem? nearest;
    var best = double.infinity;
    for (final item in _items) {
      if (!_isFalling(item)) continue;
      final distance = (_positionOf(item) - point).distance;
      if (distance <= _reach && distance < best) {
        nearest = item;
        best = distance;
      }
    }
    final item = nearest;
    if (item == null) return;
    final bomb = item.kind == FallingKind.bomb;
    bomb ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick();
    setState(() {
      _taken.add(item.id);
      _points = max(0, _points + item.kind.points);
      if (bomb) _lastBombMs = playMs;
      _hits.add(
        _Hit(
          id: item.id,
          position: _positionOf(item),
          kind: item.kind,
          atMs: playMs,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.coinRain,
      instructions: 'Toca las monedas y los diamantes. ¡Las bombas restan!',
      child: soloBody(
        arena: _arena,
        doneText: (score) => '¡Cazaste $score puntos!',
        doneIcon: Icons.monetization_on_rounded,
      ),
    );
  }

  Widget _arena(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            MinigameCounter(
              value: '$_points',
              icon: Icons.monetization_on_rounded,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MinigameTimeBar(left: 1 - playMs / rules.coinRainMs),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Transform.translate(
          offset: minigameShake(playMs - _lastBombMs, durationMs: 320),
          child: MinigameArena(
            height: 320,
            compactHeight: 262,
            colors: const [AppColors.blueMain, AppColors.blueLight],
            child: LayoutBuilder(
              builder: (context, box) {
                _area = box.biggest;
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _tap(event.localPosition),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(painter: _ScenePainter()),
                      ),
                      for (final item in _items)
                        if (_isFalling(item)) _falling(item),
                      for (final hit in _hits) ..._effects(hit),
                      if (playMs - _lastBombMs < _flashMs)
                        const Positioned.fill(
                          child: ColoredBox(color: AppColors.coinRainFlash),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _falling(FallingItem item) {
    final position = _positionOf(item);
    return Positioned(
      key: ValueKey(item.id),
      left: position.dx - _size / 2,
      top: position.dy - _size / 2,
      width: _size,
      height: _size,
      child: switch (item.kind) {
        FallingKind.bomb => const CustomPaint(painter: _BombPainter()),
        FallingKind.coin => _piece(MapAssets.coin, AppColors.coin),
        FallingKind.diamond => _piece(MapAssets.diamond, AppColors.diamond),
      },
    );
  }

  Widget _piece(String asset, Color fallback) {
    return Image.asset(
      asset,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Icon(Icons.circle, color: fallback),
    );
  }

  List<Widget> _effects(_Hit hit) {
    final bomb = hit.kind == FallingKind.bomb;
    final points = hit.kind.points;
    return [
      Positioned.fill(
        key: ValueKey('chispas-${hit.id}'),
        child: MinigameBurst(
          center: hit.position,
          seed: hit.id + 1,
          pieces: bomb ? 16 : 10,
          reach: bomb ? 80 : 56,
          duration: const Duration(milliseconds: 500),
          colors: bomb
              ? const [AppColors.minigameOut, AppColors.coin]
              : const [AppColors.medalGold, AppColors.white],
        ),
      ),
      Positioned(
        key: ValueKey('puntos-${hit.id}'),
        left: hit.position.dx - 40,
        top: hit.position.dy - 18,
        width: 80,
        child: MinigameFloat(
          text: points > 0 ? '+$points' : '$points',
          color: bomb ? AppColors.minigameOut : AppColors.pillBackground,
        ),
      ),
    ];
  }
}

/// Las nubes y el pasto de abajo.
class _ScenePainter extends CustomPainter {
  const _ScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()..color = AppColors.minigameShine;
    void puff(double x, double y, double scale) {
      for (final (dx, dy, radius) in const [
        (-26.0, 4.0, 15.0),
        (0.0, -3.0, 22.0),
        (28.0, 5.0, 14.0),
      ]) {
        canvas.drawCircle(
          Offset(x + dx * scale, y + dy * scale),
          radius * scale,
          cloud,
        );
      }
    }

    puff(size.width * 0.24, size.height * 0.2, 1);
    puff(size.width * 0.74, size.height * 0.36, 0.75);
    puff(size.width * 0.5, size.height * 0.62, 0.6);

    final top = size.height - 34;
    final grass = Path()
      ..moveTo(0, top + 8)
      ..quadraticBezierTo(
        size.width * 0.25,
        top - 12,
        size.width * 0.5,
        top + 4,
      )
      ..quadraticBezierTo(size.width * 0.75, top + 18, size.width, top - 2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(grass, Paint()..color = AppColors.tilePositive);
    canvas.drawPath(
      grass,
      Paint()
        ..color = AppColors.activeButton
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) => false;
}

/// Bomba redonda con su mecha y una chispa.
class _BombPainter extends CustomPainter {
  const _BombPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w * 0.47, w * 0.56);
    final radius = w * 0.36;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.62, w * 0.28)
        ..quadraticBezierTo(w * 0.68, w * 0.1, w * 0.84, w * 0.16),
      Paint()
        ..color = AppColors.chestPartyStrong
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: const [AppColors.trap, AppColors.characterOutline],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.minigameOut
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      center + Offset(-radius * 0.38, -radius * 0.4),
      radius * 0.18,
      Paint()..color = AppColors.minigameShine,
    );
    canvas.drawCircle(
      Offset(w * 0.86, w * 0.15),
      w * 0.09,
      Paint()..color = AppColors.coin,
    );
    canvas.drawCircle(
      Offset(w * 0.86, w * 0.15),
      w * 0.045,
      Paint()..color = AppColors.pillBackground,
    );
  }

  @override
  bool shouldRepaint(_BombPainter oldDelegate) => false;
}
