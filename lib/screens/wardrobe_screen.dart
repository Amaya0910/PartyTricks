import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/wardrobe_controller.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/category_tab_bar.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';

/// Vestuario: el personaje arriba, las categorías en el medio y los
/// cosméticos de la categoría elegida abajo. El fondo lo pone MainShellScreen.
class WardrobeScreen extends ConsumerWidget {
  const WardrobeScreen({super.key});

  /// Provisional: cosméticos que ya tiene el jugador, por categoría.
  /// Se reemplaza por los cosméticos desbloqueados del perfil
  /// (feature/player-profile). Con el mapa vacío, todas las categorías
  /// muestran su mensaje de "Aún no tienes...".
  static const Map<CosmeticCategory, List<String>> _ownedItems = {
    CosmeticCategory.shirt: ['Camisa 1'],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(wardrobeControllerProvider);

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Reemplazar por el personaje armado con los cosméticos.
                const Center(
                  child: Icon(
                    Icons.face,
                    size: 200,
                    color: AppColors.placeholderIcon,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _PhotoButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('La cámara llega pronto')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        CategoryTabBar(
          selected: selected,
          onSelected: ref.read(wardrobeControllerProvider.notifier).select,
        ),
        Expanded(
          flex: 2,
          child: ColoredBox(
            color: AppColors.white,
            // SafeArea inferior: también deja espacio para la barra de navegación.
            child: SafeArea(
              top: false,
              child: _OwnedItems(
                emptyMessage: selected.emptyMessage,
                items: _ownedItems[selected] ?? const [],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cuadrícula con los cosméticos que el jugador ya tiene. Si no tiene
/// ninguno en la categoría, muestra su mensaje en vez de espacios vacíos.
class _OwnedItems extends StatelessWidget {
  const _OwnedItems({required this.items, required this.emptyMessage});

  final List<String> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => CosmeticSlot(label: items[index]),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.photo_camera),
      label: const Text('Foto'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.activeButton,
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.inactiveButton, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}