import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/eyes_controller.dart';
import 'package:party_tricks/controllers/mouth_controller.dart';
import 'package:party_tricks/controllers/skin_tone_controller.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/chest_dialog.dart';
import 'package:party_tricks/widgets/chest_reward_dialog.dart';
import 'package:party_tricks/widgets/chest_visuals.dart';
import 'package:party_tricks/widgets/cosmetic_purchase_dialog.dart';
import 'package:party_tricks/widgets/eyes_picker.dart';
import 'package:party_tricks/widgets/mouth_picker.dart';
import 'package:party_tricks/widgets/shop_item_row.dart';
import 'package:party_tricks/widgets/stat_pill.dart';

/// Qué cosméticos muestra la lista de la Tienda.
enum ShopFilter {
  all('Todos'),
  eyes('Ojos'),
  mouth('Bocas');

  const ShopFilter(this.label);

  final String label;
}

/// Cómo se ordena la lista de cosméticos.
enum ShopSort {
  recommended('Recomendado'),
  priceAsc('Precio: menor a mayor'),
  priceDesc('Precio: mayor a menor'),
  rarityDesc('Rareza: mayor a menor'),
  rarityAsc('Rareza: menor a mayor');

  const ShopSort(this.label);

  final String label;
}

/// Un cosmético en venta, listo para dibujar en la lista.
class _ShopEntry {
  const _ShopEntry({
    required this.filter,
    required this.rarity,
    required this.title,
    required this.description,
    required this.price,
    required this.preview,
    required this.onTap,
  });

  final ShopFilter filter;
  final Rarity rarity;
  final String title;
  final String description;
  final int price;
  final Widget preview;
  final VoidCallback onTap;
}

/// Tienda de Tricks: los cofres arriba y, debajo, los cosméticos que el
/// jugador todavía no tiene (ojos y bocas), con un filtro por categoría. El
/// fondo lo pone MainShellScreen.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  ShopFilter _filter = ShopFilter.all;
  ShopSort _sort = ShopSort.recommended;

  Future<void> _openChest(BuildContext context, ChestType chest) async {
    final prize = await ChestDialog.show(context, chest);
    if (prize == null || !context.mounted) return;
    await ChestRewardDialog.show(context, chest, prize);
  }

  Future<void> _openEyes(BuildContext context, EyeStyle eyes) async {
    final bought = await CosmeticPurchaseDialog.showEyes(context, eyes);
    if (!bought || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Ya tienes los ${eyes.title}! Póntelos en el Vestuario'),
      ),
    );
  }

  Future<void> _openMouth(BuildContext context, MouthStyle mouth) async {
    final bought = await CosmeticPurchaseDialog.showMouth(context, mouth);
    if (!bought || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Ya tienes la ${mouth.title}! Póntela en el Vestuario'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eyeColor = EyeColor.colorOf(ref.watch(eyeColorProvider));
    final skin = SkinTone.colorOf(ref.watch(skinToneProvider));
    // Sin color, lo blanco de la boca toma el tono de piel.
    final mouthColor =
        MouthColor.colorOf(ref.watch(mouthColorProvider)) ?? skin;
    final entries = [
      for (final eyes in ref.watch(eyesForSaleProvider))
        _ShopEntry(
          filter: ShopFilter.eyes,
          rarity: eyes.rarity,
          title: eyes.title,
          description: eyes.description,
          price: eyes.price,
          preview: EyesThumbnail(style: eyes, color: eyeColor),
          onTap: () => _openEyes(context, eyes),
        ),
      for (final mouth in ref.watch(mouthsForSaleProvider))
        _ShopEntry(
          filter: ShopFilter.mouth,
          rarity: mouth.rarity,
          title: mouth.title,
          description: mouth.description,
          price: mouth.price,
          preview: MouthThumbnail(style: mouth, color: mouthColor),
          onTap: () => _openMouth(context, mouth),
        ),
    ];
    final visible = [
      for (final entry in entries)
        if (_filter == ShopFilter.all || entry.filter == _filter) entry,
    ];
    // List.sort no es estable: el lugar original desempata.
    final order = {for (final (i, entry) in entries.indexed) entry: i};
    int byOrder(_ShopEntry a, _ShopEntry b) => order[a]!.compareTo(order[b]!);
    int thenOrder(int result, _ShopEntry a, _ShopEntry b) =>
        result != 0 ? result : byOrder(a, b);
    visible.sort(
      (a, b) => switch (_sort) {
        ShopSort.recommended => byOrder(a, b),
        ShopSort.priceAsc => thenOrder(a.price.compareTo(b.price), a, b),
        ShopSort.priceDesc => thenOrder(b.price.compareTo(a.price), a, b),
        ShopSort.rarityDesc => thenOrder(
          b.rarity.level.compareTo(a.rarity.level),
          a,
          b,
        ),
        ShopSort.rarityAsc => thenOrder(
          a.rarity.level.compareTo(b.rarity.level),
          a,
          b,
        ),
      },
    );
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
                _FilterBar(
                  selected: _filter,
                  onSelected: (filter) => setState(() => _filter = filter),
                  sort: _sort,
                  onSortSelected: (sort) => setState(() => _sort = sort),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? _EmptyItems(filter: _filter)
                      : _ItemList(items: visible),
                ),
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

/// Fila de chips para filtrar los cosméticos por categoría.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelected,
    required this.sort,
    required this.onSortSelected,
  });

  final ShopFilter selected;
  final ValueChanged<ShopFilter> onSelected;
  final ShopSort sort;
  final ValueChanged<ShopSort> onSortSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                for (final filter in ShopFilter.values)
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: filter == selected,
                    onSelected: (_) => onSelected(filter),
                    showCheckmark: false,
                    backgroundColor: AppColors.wardrobeChip,
                    selectedColor: AppColors.blueStrong,
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: filter == selected
                          ? AppColors.white
                          : AppColors.wardrobeInk,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<ShopSort>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort, color: AppColors.wardrobeInk),
            initialValue: sort,
            onSelected: onSortSelected,
            itemBuilder: (_) => [
              for (final option in ShopSort.values)
                PopupMenuItem(value: option, child: Text(option.label)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Los cosméticos en venta, uno debajo de otro.
class _ItemList extends StatelessWidget {
  const _ItemList({required this.items});

  final List<_ShopEntry> items;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.shopListBackground,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return ShopItemRow(
            preview: item.preview,
            title: item.title,
            description: item.description,
            price: item.price,
            rarity: item.rarity,
            onTap: item.onTap,
          );
        },
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems({required this.filter});

  final ShopFilter filter;

  String get _message => switch (filter) {
    ShopFilter.all => '¡Ya tienes todos los cosméticos!',
    ShopFilter.eyes => '¡Ya tienes todos los ojos!',
    ShopFilter.mouth => '¡Ya tienes todas las bocas!',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _message,
          textAlign: TextAlign.center,
          style: const TextStyle(
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
