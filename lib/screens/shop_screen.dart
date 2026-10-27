import 'package:flutter/material.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/chest_dialog.dart';
import 'package:party_tricks/widgets/chest_visuals.dart';
import 'package:party_tricks/widgets/stat_pill.dart';

/// Tienda de Tricks: los cofres arriba y, debajo, los ítems (todavía no hay).
/// El fondo lo pone MainShellScreen.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Future<void> _openChest(BuildContext context, ChestType chest) async {
    final outcome = await ChestDialog.show(context, chest);
    if (outcome == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_messageFor(outcome))),
    );
  }

  String _messageFor(ChestOutcome outcome) => switch (outcome) {
    ChestOutcome.cosmetic => '¡Te salió un cosmético aleatorio!',
    ChestOutcome.nothing => 'Esta vez el cofre estaba vacío',
    ChestOutcome.coins => '¡Ganaste $chestCoinPrize monedas!',
    ChestOutcome.dice => '¡Ganaste un dado extra!',
  };

  @override
  Widget build(BuildContext context) {
    // SafeArea: también deja espacio para la barra de navegación.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                const _Title(),
                const _Band(label: 'COFRES'),
                _ChestRow(onTap: (chest) => _openChest(context, chest)),
                const Divider(height: 1, color: AppColors.screenBackground),
                const Expanded(child: _EmptyItems()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Text(
        'Tienda de Tricks',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.authText,
        ),
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.shopBand,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.authText,
        ),
      ),
    );
  }
}

class _ChestRow extends StatelessWidget {
  const _ChestRow({required this.onTap});

  final ValueChanged<ChestType> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          for (final (index, chest) in ChestType.values.indexed) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(
              child: _ChestCard(chest: chest, onTap: () => onTap(chest)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChestCard extends StatelessWidget {
  const _ChestCard({required this.chest, required this.onTap});

  final ChestType chest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ChestPalette.of(chest);

    return Semantics(
      button: true,
      label: '${chest.title}, ${chest.price} diamantes',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 0.8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.strong, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(child: ChestImage(chest: chest)),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatPill(
                      icon: Icons.diamond,
                      color: AppColors.diamond,
                      value: chest.price,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Aún no hay ítems en la tienda',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.authHint,
          ),
        ),
      ),
    );
  }
}