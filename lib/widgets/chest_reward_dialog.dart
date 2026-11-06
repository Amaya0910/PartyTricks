import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/eyes_controller.dart';
import 'package:party_tricks/controllers/mouth_controller.dart';
import 'package:party_tricks/controllers/skin_tone_controller.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/chest_visuals.dart';
import 'package:party_tricks/widgets/eyes_picker.dart';
import 'package:party_tricks/widgets/mouth_picker.dart';
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
            Center(
              child: _Pop(
                child: _PrizeTile(chest: chest, palette: palette, prize: prize),
              ),
            ),
            if (prize.eyes?.rarity ?? prize.mouth?.rarity
                case final rarity?) ...[
              const SizedBox(height: 12),
              Center(child: RarityBadge(rarity: rarity)),
            ],
            const SizedBox(height: 12),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: palette.strong,
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
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: palette.card,
                foregroundColor: palette.strong,
                side: BorderSide(color: palette.strong, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(
                prize.outcome == ChestOutcome.nothing ? 'Volver' : '¡Genial!',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _cosmeticName => prize.eyes?.title ?? prize.mouth?.title ?? '';
}

/// Aparece creciendo un poco, con un rebote suave.
class _Pop extends StatelessWidget {
  const _Pop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 450),
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
      ),
      child: _content(ref),
    );
  }

  Widget _content(WidgetRef ref) {
    final eyes = prize.eyes;
    final mouth = prize.mouth;
    if (eyes != null) {
      return _Framed(
        child: EyesThumbnail(
          style: eyes,
          color: EyeColor.colorOf(ref.watch(eyeColorProvider)),
        ),
      );
    }
    if (mouth != null) {
      final skin = SkinTone.colorOf(ref.watch(skinToneProvider));
      return _Framed(
        child: MouthThumbnail(
          style: mouth,
          color: MouthColor.colorOf(ref.watch(mouthColorProvider)) ?? skin,
        ),
      );
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
