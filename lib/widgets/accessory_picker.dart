import 'package:flutter/material.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';

/// Pestaña Accesorios del Vestuario: el primer espacio es "Ninguno" y luego
/// los accesorios del jugador. No conoce Riverpod: recibe lo elegido y avisa
/// cuando tocan otro (o "Ninguno", que manda null).
class AccessoryPicker extends StatelessWidget {
  const AccessoryPicker({
    super.key,
    required this.styles,
    required this.selectedStyle,
    required this.onStyleSelected,
    required this.skin,
  });

  /// Accesorios que puede elegir el jugador.
  final List<AccessoryStyle> styles;

  /// El accesorio puesto, o null si no lleva ninguno.
  final AccessoryStyle? selectedStyle;
  final ValueChanged<AccessoryStyle?> onStyleSelected;

  /// Tono de piel con el que se dibuja la cabeza.
  final Color skin;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: styles.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return CosmeticSlot(
            semanticLabel: 'Sin accesorio',
            label: 'Ninguno',
            isSelected: selectedStyle == null,
            onTap: () => onStyleSelected(null),
          );
        }
        final style = styles[index - 1];
        return CosmeticSlot(
          semanticLabel: style.title,
          preview: AccessoryThumbnail(style: style, skin: skin),
          isSelected: style == selectedStyle,
          onTap: () => onStyleSelected(style),
        );
      },
    );
  }
}

/// La cabeza del personaje con el accesorio puesto. Lo usan el Vestuario, la
/// Tienda, los cofres y la ventana de compra.
class AccessoryThumbnail extends StatelessWidget {
  const AccessoryThumbnail({
    super.key,
    required this.style,
    required this.skin,
  });

  final AccessoryStyle style;
  final Color skin;

  /// Zona de la cabeza con las orejas y la gorguera, en píxeles del lienzo
  /// (512x768).
  static const Rect _crop = Rect.fromLTWH(50, 35, 412, 390);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox.fromSize(
        size: _crop.size,
        child: ColoredBox(
          color: AppColors.white,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -_crop.left,
                top: -_crop.top,
                width: kCharacterCanvas.width,
                height: kCharacterCanvas.height,
                child: Stack(
                  children: [
                    CharacterLayer(BodyPart.cabeza.fillAsset, tint: skin),
                    CharacterLayer(BodyPart.cabeza.outlineAsset),
                    CharacterLayer(
                      style.assetFor(CharacterView.frente),
                      tint: style.skinTinted ? skin : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
