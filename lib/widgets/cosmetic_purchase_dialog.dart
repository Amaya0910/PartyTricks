import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/character_look_controller.dart';
import 'package:party_tricks/controllers/shop_controller.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/rarity.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/shop/shop_service.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/cosmetic_preview.dart';
import 'package:party_tricks/widgets/rarity_badge.dart';

/// Ventana para comprar un cosmético: tu personaje probándoselo, la
/// descripción y el botón Comprar. Devuelve true si se compró.
///
/// Se abre con [show].
class CosmeticPurchaseDialog extends ConsumerStatefulWidget {
  const CosmeticPurchaseDialog._({
    required this.title,
    required this.description,
    required this.price,
    required this.rarity,
    required this.thumbnail,
    required this.character,
    required this.buy,
  });

  final String title;
  final String description;
  final int price;
  final Rarity rarity;

  /// Dibujo del cosmético con el color elegido por el jugador.
  final Widget Function(WidgetRef ref) thumbnail;

  /// El personaje del jugador con el cosmético puesto.
  final Widget Function(WidgetRef ref) character;

  /// Hace la compra en la Tienda.
  final Future<void> Function(WidgetRef ref) buy;

  /// Abre la ventana de compra de [cosmetic] (ojos, boca, camisa o
  /// accesorio). Devuelve true si se compró.
  static Future<bool> show(BuildContext context, ShopCosmetic cosmetic) {
    return _show(
      context,
      CosmeticPurchaseDialog._(
        title: cosmetic.title,
        description: cosmetic.description,
        price: cosmetic.price,
        rarity: cosmetic.rarity,
        thumbnail: (ref) => CosmeticPreview(cosmetic),
        character: (ref) => AnimatedCharacter.fromLook(
          _wearing(ref.watch(characterLookProvider), cosmetic),
        ),
        buy: (ref) => _buy(ref.read(shopControllerProvider.notifier), cosmetic),
      ),
    );
  }

  /// El aspecto [look] con [cosmetic] puesto.
  static CharacterLook _wearing(CharacterLook look, ShopCosmetic cosmetic) {
    return switch (cosmetic) {
      EyeStyle eyes => look.copyWith(eyes: eyes),
      MouthStyle mouth => look.copyWith(mouth: mouth),
      ShirtStyle shirt => look.copyWith(shirt: shirt),
      AccessoryStyle accessory => look.copyWith(accessory: accessory),
      _ => look,
    };
  }

  static Future<void> _buy(ShopController shop, ShopCosmetic cosmetic) {
    return switch (cosmetic) {
      EyeStyle eyes => shop.buyEyes(eyes),
      MouthStyle mouth => shop.buyMouth(mouth),
      ShirtStyle shirt => shop.buyShirt(shirt),
      AccessoryStyle accessory => shop.buyAccessory(accessory),
      _ => throw ArgumentError('Cosmético desconocido: $cosmetic'),
    };
  }

  static Future<bool> _show(
    BuildContext context,
    CosmeticPurchaseDialog dialog,
  ) async {
    final bought = await showBlurredDialog<bool>(
      context,
      builder: (_) => dialog,
    );
    return bought ?? false;
  }

  @override
  ConsumerState<CosmeticPurchaseDialog> createState() =>
      _CosmeticPurchaseDialogState();
}

class _CosmeticPurchaseDialogState
    extends ConsumerState<CosmeticPurchaseDialog> {
  String? _error;

  Future<void> _buy() async {
    setState(() => _error = null);
    try {
      await widget.buy(ref);
      if (mounted) Navigator.of(context).pop(true);
    } on ShopException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Algo salió mal, intenta otra vez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(userProfileProvider).value?.coins ?? 0;
    final loading = ref.watch(shopControllerProvider);
    final missing = widget.price - coins;

    return DialogCard(
      title: widget.title,
      shadowColor: AppColors.pillShadow,
      headerShadow: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _TryOn(character: widget.character(ref)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.shopItemBorder,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: widget.thumbnail(ref),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      RarityBadge(rarity: widget.rarity),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.authText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tienes $coins monedas',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.authHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_error != null || missing > 0) ...[
              Text(
                _error ?? 'Te faltan $missing monedas',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authError,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _BuyButton(
              price: widget.price,
              isLoading: loading,
              onPressed: missing > 0 ? null : _buy,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tu personaje (con tu tono de piel) probándose el cosmético. Se ve de la
/// cintura para arriba.
class _TryOn extends StatelessWidget {
  const _TryOn({required this.character});

  final Widget character;

  static const double _width = 110;

  /// Ancho con el que se dibuja el personaje antes de recortarlo.
  static const double _zoomWidth = 150;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _width * 1.15,
      decoration: BoxDecoration(
        color: AppColors.screenBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.authAccent, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        // El personaje se dibuja más grande que el recuadro y se recorta:
        // así se ven bien la cara, los ojos y la boca.
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minWidth: _zoomWidth,
          maxWidth: _zoomWidth,
          minHeight: _zoomWidth * 1.5,
          maxHeight: _zoomWidth * 1.5,
          child: character,
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.price,
    required this.isLoading,
    required this.onPressed,
  });

  final int price;
  final bool isLoading;

  /// Null si no alcanzan las monedas.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        backgroundColor: AppColors.pillBackground,
        disabledBackgroundColor: AppColors.authField,
        foregroundColor: AppColors.authText,
        disabledForegroundColor: AppColors.authHint,
        side: const BorderSide(color: AppColors.coin, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.coin,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Comprar'),
                const SizedBox(width: 10),
                const Icon(
                  Icons.monetization_on,
                  size: 22,
                  color: AppColors.coin,
                ),
                const SizedBox(width: 4),
                Text('$price'),
              ],
            ),
    );
  }
}
