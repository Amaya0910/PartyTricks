import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/shop_controller.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/services/shop/shop_service.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/chest_visuals.dart';

/// Ventana de un cofre: sus probabilidades y el botón Comprar.
/// Devuelve el premio si se compró, o null si se cierra sin comprar.
class ChestDialog extends ConsumerStatefulWidget {
  const ChestDialog({super.key, required this.chest});

  final ChestType chest;

  static Future<ChestOutcome?> show(BuildContext context, ChestType chest) {
    return showBlurredDialog<ChestOutcome>(
      context,
      builder: (_) => ChestDialog(chest: chest),
    );
  }

  @override
  ConsumerState<ChestDialog> createState() => _ChestDialogState();
}

class _ChestDialogState extends ConsumerState<ChestDialog> {
  String? _error;

  Future<void> _buy() async {
    setState(() => _error = null);
    try {
      final outcome = await ref
          .read(shopControllerProvider.notifier)
          .buyChest(widget.chest);
      if (mounted) Navigator.of(context).pop(outcome);
    } on ShopException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Algo salió mal, intenta otra vez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chest = widget.chest;
    final palette = ChestPalette.of(chest);
    final loading = ref.watch(shopControllerProvider);

    return DialogCard(
      title: chest.title,
      accent: palette.strong,
      shadowColor: AppColors.pillShadow, // sombra negra suave, no azul
      headerShadow: false, // sin sombra bajo el título
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChestTile(chest: chest, palette: palette),
                const SizedBox(width: 12),
                Expanded(
                  child: _Odds(chest: chest, palette: palette),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.authError,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _BuyButton(
              chest: chest,
              palette: palette,
              isLoading: loading,
              onPressed: _buy,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChestTile extends StatelessWidget {
  const _ChestTile({required this.chest, required this.palette});

  final ChestType chest;
  final ChestPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.strong, width: 2),
      ),
      child: ChestImage(chest: chest),
    );
  }
}

class _Odds extends StatelessWidget {
  const _Odds({required this.chest, required this.palette});

  final ChestType chest;
  final ChestPalette palette;

  @override
  Widget build(BuildContext context) {
    final odds = chest.odds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: palette.strong,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Estadísticas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _OddsRow('Cosmético aleatorio:', odds.cosmetic),
        _OddsRow('Nada:', odds.nothing),
        _OddsRow('$chestCoinPrize Monedas:', odds.coins),
        _OddsRow('Dado extra:', odds.dice),
      ],
    );
  }
}

class _OddsRow extends StatelessWidget {
  const _OddsRow(this.label, this.percent);

  final String label;
  final int percent;

  static const _style = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.authText,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _style)),
          Text('$percent%', style: _style),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.chest,
    required this.palette,
    required this.isLoading,
    required this.onPressed,
  });

  final ChestType chest;
  final ChestPalette palette;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        backgroundColor: palette.card,
        disabledBackgroundColor: palette.card,
        foregroundColor: palette.strong,
        side: BorderSide(color: palette.strong, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.strong,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Comprar'),
                const SizedBox(width: 10),
                const Icon(Icons.diamond, size: 20),
                const SizedBox(width: 4),
                Text('${chest.price}'),
              ],
            ),
    );
  }
}
