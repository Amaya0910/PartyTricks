import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/eyes_controller.dart';
import 'package:party_tricks/controllers/face_photo_controller.dart';
import 'package:party_tricks/controllers/mouth_controller.dart';
import 'package:party_tricks/controllers/skin_tone_controller.dart';
import 'package:party_tricks/controllers/wardrobe_controller.dart';
import 'package:party_tricks/models/cosmetic_category.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/screens/face_photo_screen.dart';
import 'package:party_tricks/services/character/character_service.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/category_tab_bar.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';
import 'package:party_tricks/widgets/eyes_picker.dart';
import 'package:party_tricks/widgets/mouth_picker.dart';
import 'package:party_tricks/widgets/skin_tone_picker.dart';

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

  /// Guarda un cambio del personaje y, si falla, muestra el mensaje.
  Future<void> _save(
    BuildContext context,
    Future<void> Function() change,
  ) async {
    try {
      await change();
    } on CharacterException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(wardrobeControllerProvider);
    final skinTone = ref.watch(skinToneProvider);
    final eyeStyle = ref.watch(eyeStyleProvider);
    final eyeColor = ref.watch(eyeColorProvider);
    final ownedEyes = ref.watch(ownedEyesProvider);
    final mouthStyle = ref.watch(mouthStyleProvider);
    final mouthColor = ref.watch(mouthColorProvider);
    final ownedMouths = ref.watch(ownedMouthsProvider);
    final skinColor = SkinTone.colorOf(skinTone);

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Falta agregar los cosméticos equipados (clothing).
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AnimatedCharacter(
                      skinTone: skinColor,
                      eyes: eyeStyle,
                      eyeColor: EyeColor.colorOf(eyeColor),
                      mouth: mouthStyle,
                      mouthColor: MouthColor.colorOf(mouthColor),
                      facePhoto: ref.watch(facePhotoProvider),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _PhotoButton(
                    onPressed: () =>
                        Navigator.of(context).push(FacePhotoScreen.route()),
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
              child: switch (selected) {
                CosmeticCategory.skin => SkinTonePicker(
                  selected: skinTone,
                  onSelected: (index) => _save(
                    context,
                    () => ref.read(skinToneControllerProvider).select(index),
                  ),
                ),
                CosmeticCategory.eyes => EyesPicker(
                  styles: ownedEyes,
                  selectedStyle: eyeStyle,
                  onStyleSelected: (style) => _save(
                    context,
                    () => ref.read(eyesControllerProvider).selectStyle(style),
                  ),
                  colors: AppColors.eyeColors,
                  selectedColor: eyeColor,
                  onColorSelected: (index) => _save(
                    context,
                    () => ref.read(eyesControllerProvider).selectColor(index),
                  ),
                ),
                CosmeticCategory.mouth => MouthPicker(
                  styles: ownedMouths,
                  selectedStyle: mouthStyle,
                  onStyleSelected: (style) => _save(
                    context,
                    () => ref.read(mouthControllerProvider).selectStyle(style),
                  ),
                  colors: MouthColor.swatches(skinColor),
                  selectedColor: mouthColor,
                  onColorSelected: (index) => _save(
                    context,
                    () => ref.read(mouthControllerProvider).selectColor(index),
                  ),
                ),
                _ => _OwnedItems(
                  emptyMessage: selected.emptyMessage,
                  items: _ownedItems[selected] ?? const [],
                ),
              },
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
      itemBuilder: (context, index) =>
          CosmeticSlot(semanticLabel: items[index]),
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
