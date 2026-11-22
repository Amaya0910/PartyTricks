import 'package:flutter/material.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';

/// Pestaña Pantalón del Vestuario: el primer espacio es "Ninguno" (una X
/// roja) y luego los pantalones del jugador. No conoce Riverpod: recibe lo
/// elegido y avisa cuando tocan otro (o "Ninguno", que manda null).
class PantsPicker extends StatelessWidget {
  const PantsPicker({
    super.key,
    required this.styles,
    required this.selectedStyle,
    required this.onStyleSelected,
    required this.skin,
  });

  /// Pantalones que puede elegir el jugador.
  final List<PantsStyle> styles;

  /// El pantalón puesto, o null si no lleva ninguno.
  final PantsStyle? selectedStyle;
  final ValueChanged<PantsStyle?> onStyleSelected;

  /// Tono de piel con el que se dibuja el cuerpo.
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
            semanticLabel: 'Sin pantalón',
            preview: const NoneMark(),
            isSelected: selectedStyle == null,
            onTap: () => onStyleSelected(null),
          );
        }
        final style = styles[index - 1];
        return CosmeticSlot(
          semanticLabel: style.title,
          preview: PantsThumbnail(style: style, skin: skin),
          isSelected: style == selectedStyle,
          onTap: () => onStyleSelected(style),
        );
      },
    );
  }
}

/// La cadera y las piernas del personaje con el pantalón puesto. Lo usan el
/// Vestuario, la Tienda, los cofres y la ventana de compra.
class PantsThumbnail extends StatelessWidget {
  const PantsThumbnail({super.key, required this.style, required this.skin});

  final PantsStyle style;
  final Color skin;

  /// Zona de la cadera y los muslos, en píxeles del lienzo (512x968).
  static const Rect _crop = Rect.fromLTWH(150, 670, 212, 170);

  static const _legs = [
    BodyPart.cuerpo,
    BodyPart.piernaIzquierda,
    BodyPart.piernaDerecha,
  ];

  @override
  Widget build(BuildContext context) {
    final asset = style.assetFor(CharacterView.frente);
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
                    for (final part in _legs)
                      CharacterLayer(part.fillAsset, tint: skin),
                    for (final part in _legs) CharacterLayer(part.outlineAsset),
                    if (asset != null) CharacterLayer(asset),
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
