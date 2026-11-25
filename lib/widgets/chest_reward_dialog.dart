import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/chest_visuals.dart';
import 'package:party_tricks/widgets/cosmetic_preview.dart';
import 'package:party_tricks/widgets/fx/chunky_button.dart';
import 'package:party_tricks/widgets/fx/confetti_burst.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';
import 'package:party_tricks/widgets/rarity_badge.dart';

/// Ventana con lo que salió del cofre: el cosmético, las monedas, el dado
/// extra o el cofre vacío. Usa los colores del cofre que se abrió, igual que
/// la ventana de compra.
class ChestRewardDialog extends ConsumerWidget {
  const ChestRewardDialog({
    super.key,
    required this.chest,
    required this.prize,
  });

  final ChestType chest;
  final ChestPrize prize;

  static Future<void> show(
    BuildContext context,
    ChestType chest,
    ChestPrize prize,
  ) {
    return showBlurredDialog<void>(
      context,
      builder: (_) => ChestRewardDialog(chest: chest, prize: prize),
    );
  }

  String get _title => switch (prize.outcome) {
    ChestOutcome.cosmetic => '¡Cosmético nuevo!',
    ChestOutcome.coins => '¡Monedas!',
    ChestOutcome.dice => '¡Dado extra!',
    ChestOutcome.nothing => 'Cofre vacío',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ChestPalette.of(chest);
    final profile = ref.watch(userProfileProvider).value;

    final (:headline, :detail) = switch (prize.outcome) {
      ChestOutcome.cosmetic => (
        headline: _cosmeticName,
        detail: 'Ya está en tu Vestuario',
      ),
      ChestOutcome.coins => (
        headline: '+$chestCoinPrize monedas',
        detail: 'Ahora tienes ${profile?.coins ?? 0} monedas',
      ),
      ChestOutcome.dice => (
        headline: '+1 dado extra',
        detail: 'Ahora tienes ${profile?.extraDice ?? 0} dados extra',
      ),
      ChestOutcome.nothing => (
        headline: 'No salió nada',
        detail: '¡Suerte con el próximo!',
      ),
    };

    return DialogCard(
      title: _title,
      accent: palette.strong,
      shadowColor: AppColors.pillShadow,
      headerShadow: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Aquí va el premio. Es un widget aparte para poder cambiarlo
            // por una animación de sorteo cuando exista.
            // El premio aparece con un rebote; si hubo premio, con confeti.
            SizedBox(
              height: _PrizeTile._size + 20,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (prize.outcome != ChestOutcome.nothing)
                    _Rays(color: palette.card),
                  _Pop(
                    child: _PrizeTile(
                      chest: chest,
                      palette: palette,
                      prize: prize,
                    ),
                  ),
                  if (prize.outcome != ChestOutcome.nothing)
                    const Positioned.fill(child: ConfettiBurst()),
                ],
              ),
            ),
            if (prize.cosmetic?.rarity case final rarity?) ...[
              const SizedBox(height: 12),
              Center(child: RarityBadge(rarity: rarity)),
            ],
            const SizedBox(height: 12),
            PopIn(
              delay: const Duration(milliseconds: 250),
              child: Text(
                headline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: palette.strong,
                  shadows: const [
                    Shadow(color: AppColors.white, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.authText,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ChunkyButton(
                color: palette.card,
                edgeColor: palette.strong,
                borderColor: palette.strong,
                radius: 24,
                depth: 5,
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: Center(
                  child: Text(
                    prize.outcome == ChestOutcome.nothing
                        ? 'Volver'
                        : '¡Genial!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: palette.strong,
                      shadows: const [
                        Shadow(color: AppColors.white, offset: Offset(0, 1.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _cosmeticName => prize.cosmetic?.title ?? '';
}

/// Aparece creciendo un poco, con un rebote suave.
class _Pop extends StatelessWidget {
  const _Pop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}

/// El cuadro grande con el dibujo del premio, con el estilo del cofre.
class _PrizeTile extends ConsumerWidget {
  const _PrizeTile({
    required this.chest,
    required this.palette,
    required this.prize,
  });

  final ChestType chest;
  final ChestPalette palette;
  final ChestPrize prize;

  static const double _size = 150;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.strong, width: 3),
        boxShadow: [
          BoxShadow(
            color: palette.strong,
            blurRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _content(ref),
    );
  }

  Widget _content(WidgetRef ref) {
    if (prize.cosmetic case final cosmetic?) {
      return _Framed(child: CosmeticPreview(cosmetic));
    }
    return switch (prize.outcome) {
      ChestOutcome.coins => _Asset(
        'assets/images/juego/moneda.png',
        Icons.monetization_on,
        AppColors.coin,
      ),
      ChestOutcome.dice => _Asset(
        'assets/images/juego/dado_6.png',
        Icons.casino,
        palette.strong,
      ),
      _ => Opacity(opacity: 0.55, child: ChestImage(chest: chest)),
    };
  }
}

/// Rayos de luz detrás del premio: crecen y dan media vuelta al aparecer.
/// La animación termina sola (no se repite).
class _Rays extends StatelessWidget {
  const _Rays({required this.color});

  final Color color;

  static const double _size = 230;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.rotate(
        angle: t * math.pi / 2,
        child: Transform.scale(scale: 0.4 + 0.6 * t, child: child),
      ),
      child: SizedBox.square(
        dimension: _size,
        child: CustomPaint(painter: _RaysPainter(color)),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color);

  final Color color;

  static const int _rays = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    const step = 2 * math.pi / _rays;
    for (var i = 0; i < _rays; i++) {
      final a = i * step;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * _cos(a - step / 4),
          center.dy + radius * _sin(a - step / 4),
        )
        ..lineTo(
          center.dx + radius * _cos(a + step / 4),
          center.dy + radius * _sin(a + step / 4),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  static double _cos(double a) => math.cos(a);
  static double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) => oldDelegate.color != color;
}

/// Fondo blanco redondeado para los dibujos de la cara.
class _Framed extends StatelessWidget {
  const _Framed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: AppColors.white,
        child: Padding(padding: const EdgeInsets.all(4), child: child),
      ),
    );
  }
}

class _Asset extends StatelessWidget {
  const _Asset(this.asset, this.fallback, this.fallbackColor);

  final String asset;
  final IconData fallback;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(fallback, size: 72, color: fallbackColor),
    );
  }
}
