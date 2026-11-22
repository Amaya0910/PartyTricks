import 'package:flutter/material.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/mouth_layer.dart';
import 'package:party_tricks/widgets/color_strip.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';

/// Pestaña Boca del Vestuario: arriba la línea de colores y abajo las bocas
/// del jugador, cada una con el color elegido. No conoce Riverpod: recibe
/// lo elegido y avisa cuando tocan otra boca u otro color.
class MouthPicker extends StatelessWidget {
  const MouthPicker({
    super.key,
    required this.styles,
    required this.selectedStyle,
    required this.onStyleSelected,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  /// Bocas que puede elegir el jugador.
  final List<MouthStyle> styles;
  final MouthStyle selectedStyle;
  final ValueChanged<MouthStyle> onStyleSelected;

  /// Colores de la línea. El primero es "sin color" y se muestra con el
  /// tono de piel, que es el que toma la boca.
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
                semanticLabel: 'Boca ${style.number}',
                preview: MouthThumbnail(style: style, color: color),
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

/// Recorte del lienzo del personaje donde está dibujada la boca. Lo usan el
/// Vestuario y la Tienda.
class MouthThumbnail extends StatelessWidget {
  const MouthThumbnail({super.key, required this.style, required this.color});

  final MouthStyle style;

  /// Color de la parte blanca (el tono de piel si no hay color elegido).
  final Color color;

  /// Zona de la boca, en píxeles del lienzo (512x968).
  static const Rect _crop = Rect.fromLTWH(
    176,
    288 + kCharacterTopMargin,
    160,
    80,
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
                child: MouthLayer(style: style, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
