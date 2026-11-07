import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/game_engine/minigame_content.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Puja Secreta: cada uno tiene 15 fichas para tres pujas en secreto. Gana
/// cada vuelta la puja más alta que nadie más hizo: las repetidas se anulan y
/// las fichas se gastan igual. Gana quien gane más vueltas.
class SecretBidGame extends MinigameWidget {
  const SecretBidGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<SecretBidGame> createState() => _SecretBidGameState();
}

class _SecretBidGameState extends State<SecretBidGame>
    with SingleTickerProviderStateMixin, MinigameClock, MinigameRounds {
  /// Cuánto tarda en voltearse cada ficha.
  static const int _flipEachMs = 420;

  /// Cuándo se sabe quién ganó la vuelta, desde que empezó a revelarse.
  int get _verdictMs => game.picks.length * _flipEachMs + 300;

  int get _myChips => game.chips[widget.myId] ?? 0;

  @override
  void onReveal(MinigameState before) => HapticFeedback.lightImpact();

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.secretBid,
      instructions:
          'Puja fichas en secreto. Gana la más alta que nadie repita. '
          'Tienes ${rules.bidChips} para ${rules.bidRounds} pujas.',
      child: inIntro
          ? MinigameIntro(leftMs: rules.introMs - elapsedMs)
          : _body(),
    );
  }

  Widget _body() {
    final revealing = this.revealing;
    final round = min(revealing ? game.stage : game.stage + 1, rules.bidRounds);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: MinigamePill(
                text: 'Puja $round de ${rules.bidRounds}',
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Flexible(
              child: MinigamePill(
                text: '$_myChips fichas',
                icon: Icons.toll_rounded,
                fontSize: 14,
                color: AppColors.coin,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MinigameArena(
          height: 262,
          compactHeight: 224,
          colors: const [AppColors.bidVelvet, AppColors.bidVelvetDark],
          child: revealing ? _reveal() : _choice(),
        ),
        const SizedBox(height: 6),
        MinigameStandings(
          game: game,
          players: widget.players,
          trailing: (id) => _stars(id, revealing),
        ),
      ],
    );
  }

  Widget? _stars(String id, bool revealing) {
    var stars = game.points[id] ?? 0;
    // La estrella de esta vuelta aparece cuando se sabe quién ganó.
    if (revealing &&
        revealClockMs < _verdictMs &&
        highestUniqueBid(game.picks) == id) {
      stars--;
    }
    final ready = !revealing && game.scores.containsKey(id);
    final hidden = revealing && revealClockMs < _verdictMs;
    final chips = (game.chips[id] ?? 0) + (hidden ? game.picks[id] ?? 0 : 0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$chips',
          style: minigameTextStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.coin,
          ),
        ),
        const Icon(Icons.toll_rounded, size: 13, color: AppColors.coin),
        for (var i = 0; i < stars; i++)
          const Icon(Icons.star_rounded, size: 15, color: AppColors.medalGold),
        if (ready)
          const Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: AppColors.reactionGo,
          ),
      ],
    );
  }

  Widget _choice() {
    if (!active) {
      return const Center(
        child: MinigameOutlinedText('Los demás están pujando', fontSize: 20),
      );
    }
    if (hasPicked) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_rounded,
              color: AppColors.medalGold,
              size: 48,
            ),
            const SizedBox(height: 8),
            const MinigameOutlinedText('¡Puja lista!', fontSize: 26),
            const SizedBox(height: 4),
            Text(
              'Esperando a los demás...',
              style: minigameTextStyle.copyWith(color: AppColors.white),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        children: [
          MinigameTimeBar(
            left: choiceLeftMs / rules.bidChoiceMs,
            color: AppColors.medalGold,
            track: AppColors.bidVelvetDark,
          ),
          const Spacer(),
          for (final row in const [
            [1, 2, 3, 4, 5],
            [6, 7, 8, 9, 10],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final bid in row)
                    _BidChip(
                      value: bid,
                      enabled: bid <= _myChips,
                      onTap: () => pick(bid),
                    ),
                ],
              ),
            ),
          const Spacer(),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => pick(0),
            child: Text(
              'Pasar y guardar mis fichas',
              style: minigameTextStyle.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reveal() {
    final players = widget.players;
    final bids = game.picks;
    final winner = highestUniqueBid(bids);
    final verdict = revealClockMs >= _verdictMs;
    final repeated = _repeatedBids(bids);
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final (index, entry) in bids.entries.indexed)
                          _RevealedBid(
                            name: players.nameOf(entry.key),
                            color: players.colorOf(entry.key),
                            bid: entry.value,
                            turned: revealClockMs >= (index + 1) * _flipEachMs,
                            cancelled:
                                verdict && repeated.contains(entry.value),
                            won: verdict && entry.key == winner,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: verdict
                      ? MinigameOutlinedText(
                          winner == null
                              ? '¡Nadie gana esta puja!'
                              : '¡Gana ${players.nameOf(winner)}!',
                          fontSize: 22,
                          color: AppColors.medalGold,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (verdict && winner != null)
          const Positioned.fill(
            child: MinigameBurst(
              colors: [AppColors.medalGold, AppColors.white],
              reach: 150,
            ),
          ),
      ],
    );
  }

  /// Las pujas que hizo más de uno.
  Set<int> _repeatedBids(Map<String, int> bids) {
    final seen = <int>{};
    final repeated = <int>{};
    for (final bid in bids.values) {
      if (bid > 0 && !seen.add(bid)) repeated.add(bid);
    }
    return repeated;
  }
}

/// Ficha de póker con la puja. Se hunde al tocarla.
class _BidChip extends StatelessWidget {
  const _BidChip({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final bool enabled;
  final VoidCallback onTap;

  static const double _size = 50;
  static const double _compactSize = 44;

  @override
  Widget build(BuildContext context) {
    final size = MinigameAccent.compactOf(context) ? _compactSize : _size;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: _ChipFace(size: size, label: '$value'),
      ),
    );
  }
}

class _ChipFace extends StatelessWidget {
  const _ChipFace({required this.size, required this.label, this.color});

  final double size;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.coin;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ChipPainter(color: color),
        child: Center(
          child: Text(
            label,
            style: minigameTextStyle.copyWith(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w700,
              color: minigameShade(color, 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ficha redonda con el borde a rayas.
class _ChipPainter extends CustomPainter {
  _ChipPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center + const Offset(0, 2),
      radius,
      Paint()..color = minigameShade(color, 0.5),
    );
    canvas.drawCircle(center, radius, Paint()..color = color);
    final stripe = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.2;
    final ring = Rect.fromCircle(center: center, radius: radius * 0.88);
    for (var i = 0; i < 8; i++) {
      canvas.drawArc(ring, i * pi / 4, pi / 8, false, stripe);
    }
    canvas.drawCircle(
      center,
      radius * 0.68,
      Paint()..color = AppColors.pillBackground,
    );
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.color != color;
}

/// La puja de un jugador: primero boca abajo, luego da la vuelta.
class _RevealedBid extends StatelessWidget {
  const _RevealedBid({
    required this.name,
    required this.color,
    required this.bid,
    required this.turned,
    required this.cancelled,
    required this.won,
  });

  final String name;
  final Color color;
  final int bid;
  final bool turned;
  final bool cancelled;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final label = bid == 0 ? '–' : '$bid';
    final chipColor = cancelled ? AppColors.minigameTrack : color;
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: won ? 1.22 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: turned ? 1 : 0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              builder: (context, turn, _) {
                final back = turn < 0.5;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(turn * pi),
                  child: back
                      ? _ChipFace(
                          size: 56,
                          label: '?',
                          color: AppColors.bidHidden,
                        )
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: _ChipFace(
                            size: 56,
                            label: label,
                            color: chipColor,
                          ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: minigameTextStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: won ? AppColors.medalGold : AppColors.white,
            ),
          ),
          Text(
            cancelled ? 'se anuló' : ' ',
            style: minigameTextStyle.copyWith(
              fontSize: 11,
              color: AppColors.pillBackground,
            ),
          ),
        ],
      ),
    );
  }
}
