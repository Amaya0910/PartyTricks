import 'package:flutter/material.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/color_strip.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';

/// Pestaña Cabello del Vestuario: arriba la línea de colores (para los
/// cabellos blancos) y abajo el espacio "Ninguno", con una X roja, y los
/// cabellos del jugador. No conoce Riverpod: recibe lo elegido y avisa cuando
/// tocan otro cabello (o "Ninguno", que manda null) u otro color.
class HairPicker extends StatelessWidget {
  const HairPicker({
    super.key,
    required this.styles,
    required this.selectedStyle,
    required this.onStyleSelected,
    required this.skin,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  /// Cabellos que puede elegir el jugador.
  final List<HairStyle> styles;

  /// El cabello puesto, o null si no lleva ninguno.
  final HairStyle? selectedStyle;
  final ValueChanged<HairStyle?> onStyleSelected;

  /// Tono de piel con el que se dibuja la cabeza.
  final Color skin;

  final List<Color> colors;

  /// Posición del color elegido en [colors].
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final color = colors[selectedColor.clamp(0, colors.length - 1)];

    return Column(
      children: [
        ColorStrip(
          colors: colors,
          firstIsNone: true,
          selected: selectedColor,
          onSelected: onColorSelected,
        ),
        Expanded(
          child: GridView.builder(
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
                  semanticLabel: 'Sin cabello',
                  preview: const NoneMark(),
                  isSelected: selectedStyle == null,
                  onTap: () => onStyleSelected(null),
                );
              }
              final style = styles[index - 1];
              return CosmeticSlot(
                semanticLabel: style.title,
                preview: HairThumbnail(style: style, skin: skin, color: color),
                isSelected: style == selectedStyle,
                onTap: () => onStyleSelected(style),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// La cabeza del personaje con el cabello puesto. Lo usan el Vestuario, la
/// Tienda, los cofres y la ventana de compra. [color] solo se aplica a los
/// cabellos blancos.
class HairThumbnail extends StatelessWidget {
  const HairThumbnail({
    super.key,
    required this.style,
    required this.skin,
    required this.color,
  });

  final HairStyle style;
  final Color skin;
  final Color color;

  /// Zona de la cabeza con el cabello, en píxeles del lienzo (512x968).
  static const Rect _crop = Rect.fromLTWH(16, 20, 480, 550);

  @override
  Widget build(BuildContext context) {
    final tint = style.tintable ? color : null;
    final back = style.backAssetFor(CharacterView.frente);
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
                    if (back != null) CharacterLayer(back, tint: tint),
                    CharacterLayer(BodyPart.cabeza.fillAsset, tint: skin),
                    CharacterLayer(BodyPart.cabeza.outlineAsset),
                    CharacterLayer(
                      style.assetFor(CharacterView.frente),
                      tint: tint,
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
