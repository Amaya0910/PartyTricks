import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/shop/cosmetic_picker.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/chest_visuals.dart';
import 'package:party_tricks/widgets/cosmetic_preview.dart';
import 'package:party_tricks/widgets/rarity_badge.dart';

/// Ventana con la probabilidad de cada cosmético cuando un cofre da un
/// "Cosmético aleatorio". Solo cuenta los que el jugador todavía no tiene
/// (los que ya tiene no pueden salir), agrupados por rareza.
class CosmeticOddsDialog extends ConsumerWidget {
  const CosmeticOddsDialog({super.key, required this.chest});

  final ChestType chest;

  static Future<void> show(BuildContext context, ChestType chest) {
    return showBlurredDialog<void>(
      context,
      builder: (_) => CosmeticOddsDialog(chest: chest),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ChestPalette.of(chest);
    final profile = ref.watch(userProfileProvider).value;
    final chances = const CosmeticPicker().chances(
      ownedEyes: profile?.ownedEyes ?? const {},
      ownedMouths: profile?.ownedMouths ?? const {},
      ownedShirts: profile?.ownedShirts ?? const {},
      ownedAccessories: profile?.ownedAccessories ?? const {},
    );

    return DialogCard(
      title: 'Cosméticos',
      accent: palette.strong,
      shadowColor: AppColors.pillShadow,
      headerShadow: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Si te sale un cosmético (${chest.odds.cosmetic}% del cofre), '
              'esta es la probabilidad de cada uno. Los que ya tienes no '
              'salen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.authText,
              ),
            ),
            const SizedBox(height: 10),
            if (chances.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '¡Ya tienes todos los cosméticos! Si el cofre da un '
                  'cosmético, recibirás monedas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authHint,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final rarity in Rarity.values.reversed)
                      ..._group(rarity, [
                        for (final c in chances)
                          if (c.rarity == rarity) c,
                      ]),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                backgroundColor: palette.card,
                foregroundColor: palette.strong,
                side: BorderSide(color: palette.strong, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _group(Rarity rarity, List<CosmeticChance> group) {
    if (group.isEmpty) return const [];
    final total = group.fold<double>(0, (sum, c) => sum + c.percent);
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: Row(
          children: [
            RarityBadge(rarity: rarity),
            const Spacer(),
            Text(
              'En total ${_format(total)}%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: rarity.color,
              ),
            ),
          ],
        ),
      ),
      for (final c in group)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _OddsTile(chance: c),
        ),
    ];
  }

  static String _format(double percent) {
    final text = percent.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}

class _OddsTile extends StatelessWidget {
  const _OddsTile({required this.chance});

  final CosmeticChance chance;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.shopItemBorder, width: 2),
      ),
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1.6,
            child: CosmeticPreview(chance.cosmetic),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              chance.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.wardrobeInk,
              ),
            ),
          ),
          Text(
            '${CosmeticOddsDialog._format(chance.percent)}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.authText,
            ),
          ),
        ],
      ),
    );
  }
}
