import 'package:flutter/material.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/rarity_badge.dart';
import 'package:party_tricks/widgets/cosmetic_slot.dart';
import 'package:party_tricks/widgets/stat_pill.dart';

/// Un artículo de la Tienda, como en el mockup: el dibujo en un cuadro
/// punteado a la izquierda y, a la derecha, el nombre, la descripción y el
/// precio en monedas. Solo dibuja; avisa con [onTap].
class ShopItemRow extends StatelessWidget {
  const ShopItemRow({
    super.key,
    required this.preview,
    required this.title,
    required this.description,
    required this.price,
    required this.onTap,
    this.rarity,
  });

  final Widget preview;
  final String title;
  final String description;

  /// Precio en monedas.
  final int price;
  final VoidCallback onTap;

  /// Rareza del cosmético (se muestra al lado del precio).
  final Rarity? rarity;

  static const double _height = 96;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '$title, $price monedas${rarity == null ? '' : ', ${rarity!.label}'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: _height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _Dashed(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: preview,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Dashed(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.wardrobeInk,
                          ),
                        ),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.authText,
                          ),
                        ),
                        Row(
                          children: [
                            StatPill(
                              icon: Icons.monetization_on,
                              color: AppColors.coin,
                              value: price,
                            ),
                            if (rarity != null) ...[
                              const Spacer(),
                              RarityBadge(rarity: rarity!),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recuadro blanco con el borde punteado celeste.
class _Dashed extends StatelessWidget {
  const _Dashed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: AppColors.shopItemBorder,
          strokeWidth: 2,
          radius: 10,
        ),
        child: child,
      ),
    );
  }
}
