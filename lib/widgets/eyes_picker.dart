import 'package:flutter/material.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/eyes_layer.dart';
import 'package:party_tricks/widgets/color_strip.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';

/// Pestaña Ojos del Vestuario: arriba la línea de colores y abajo los ojos
/// del jugador, cada uno con el color elegido. No conoce Riverpod: recibe
/// lo elegido y avisa cuando tocan otro ojo u otro color.
class EyesPicker extends StatelessWidget {
  const EyesPicker({
    super.key,
    required this.styles,
    required this.selectedStyle,
    required this.onStyleSelected,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  /// Ojos que puede elegir el jugador.
  final List<EyeStyle> styles;
  final EyeStyle selectedStyle;
  final ValueChanged<EyeStyle> onStyleSelected;

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
          firstIsNone: true,
          colors: colors,
          selected: selectedColor,
          onSelected: onColorSelected,
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: styles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final style = styles[index];
              return CosmeticSlot(
                semanticLabel: 'Ojo ${style.number}',
                preview: EyesThumbnail(style: style, color: color),
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

/// Recorte del lienzo del personaje donde están dibujados los ojos. Lo
/// usan el Vestuario y la Tienda.
class EyesThumbnail extends StatelessWidget {
  const EyesThumbnail({super.key, required this.style, required this.color});

  final EyeStyle style;
  final Color color;

  /// Zona de los ojos, en píxeles del lienzo (512x968).
  static const Rect _crop = Rect.fromLTWH(
    116,
    160 + kCharacterTopMargin,
    280,
    120,
  );

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
                child: EyesLayer(style: style, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
