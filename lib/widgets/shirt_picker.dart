import 'package:flutter/material.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';

/// Pestaña Camisa del Vestuario: las camisas del jugador, cada una puesta
/// sobre el cuerpo con su tono de piel. No conoce Riverpod: recibe lo elegido
/// y avisa cuando tocan otra camisa.
class ShirtPicker extends StatelessWidget {
  const ShirtPicker({
    super.key,
    required this.styles,
    required this.selectedStyle,
    required this.onStyleSelected,
    required this.skin,
  });

  /// Camisas que puede elegir el jugador.
  final List<ShirtStyle> styles;
  final ShirtStyle selectedStyle;
  final ValueChanged<ShirtStyle> onStyleSelected;

  /// Tono de piel con el que se dibuja el cuerpo.
  final Color skin;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
          semanticLabel: style.title,
          preview: ShirtThumbnail(style: style, skin: skin),
          isSelected: style == selectedStyle,
          onTap: () => onStyleSelected(style),
        );
      },
    );
  }
}

/// El torso y los brazos del personaje con la camisa puesta. Lo usan el
/// Vestuario, la Tienda, los cofres y la ventana de compra.
class ShirtThumbnail extends StatelessWidget {
  const ShirtThumbnail({super.key, required this.style, required this.skin});

  final ShirtStyle style;
  final Color skin;

  /// Zona del torso y los brazos, en píxeles del lienzo (512x768).
  static const Rect _crop = Rect.fromLTWH(120, 296, 272, 292);

  @override
  Widget build(BuildContext context) {
    Widget part(BodyPart part, String? sleeve, {bool shirt = false}) {
      return Stack(
        children: [
          CharacterLayer(part.fillAsset, tint: skin),
          CharacterLayer(part.outlineAsset),
          if (shirt)
            CharacterLayer(
              style.bodyAsset(CharacterView.frente),
              tint: style.tint,
            ),
          if (sleeve != null) CharacterLayer(sleeve, tint: style.tint),
        ],
      );
    }

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
                    part(BodyPart.cuerpo, null, shirt: true),
                    part(
                      BodyPart.brazoIzquierdo,
                      style.frontSleeve(left: true),
                    ),
                    part(BodyPart.brazoDerecho, style.frontSleeve(left: false)),
                    part(BodyPart.manoIzquierda, null),
                    part(BodyPart.manoDerecha, null),
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
