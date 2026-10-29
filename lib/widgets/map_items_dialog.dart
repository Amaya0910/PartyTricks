import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/shop_items.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';

/// Qué muestra el diálogo de ítems.
enum ItemsMode { shop, backpack }

/// Ícono de cada ítem.
IconData itemIcon(ShopItem item) => switch (item) {
  ShopItem.extraDie3 ||
  ShopItem.extraDie6 ||
  ShopItem.extraDie9 => Icons.casino,
  ShopItem.movementBoost => Icons.fast_forward,
  ShopItem.trap => Icons.dangerous,
  ShopItem.shield => Icons.shield,
  ShopItem.diamondBoost => Icons.diamond,
};

/// La tienda del mapa o tu mochila, con la partida en vivo: al comprar o
/// usar algo se actualiza sola. La tienda se cierra cuando sales de ella.
class MapItemsDialog extends ConsumerWidget {
  const MapItemsDialog({
    super.key,
    required this.roomId,
    required this.myId,
    required this.mode,
    required this.onAction,
  });

  final String roomId;
  final String myId;
  final ItemsMode mode;
  final void Function(GameAction action) onAction;

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    required String myId,
    required ItemsMode mode,
    required void Function(GameAction action) onAction,
  }) {
    return showBlurredDialog<void>(
      context,
      builder: (_) => MapItemsDialog(
        roomId: roomId,
        myId: myId,
        mode: mode,
        onAction: onAction,
      ),
    );
  }

  /// La tienda solo sirve mientras estás en ella.
  bool _shopping(GameState? game) =>
      game != null &&
      game.phase == GamePhase.shopping &&
      game.currentPlayerId == myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mode == ItemsMode.shop) {
      ref.listen(gameProvider(roomId), (_, next) {
        if (!_shopping(next.value)) Navigator.of(context).maybePop();
      });
    }
    final game = ref.watch(gameProvider(roomId)).value;
    final me = game?.players[myId];
    if (game == null || me == null) return const SizedBox.shrink();
    final engine = ref.watch(gameEngineProvider);
    final myTurn = game.currentPlayerId == myId;

    String? problemFor(ShopItem item) {
      if (mode == ItemsMode.shop) {
        return _shopping(game) ? engine.whyCannotBuy(game, item) : 'Cerrada';
      }
      if (item.passive) return 'Se usa solo';
      if (!myTurn || game.phase != GamePhase.rolling) {
        return 'Úsalo en tu turno, antes del dado';
      }
      return engine.whyCannotUse(game, item);
    }

    return DialogCard(
      title: mode == ItemsMode.shop ? 'Tienda' : 'Mochila',
      accent: AppColors.tileShop,
      // La tarjeta no limita el alto; sin esto la lista se sale de la
      // pantalla en los teléfonos pequeños.
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: AppColors.coin),
                Text(
                  ' ${me.coins}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Flexible(
              child: ItemList(
                player: me,
                mode: mode,
                problemFor: problemFor,
                onPressed: (item) => onAction(
                  mode == ItemsMode.shop
                      ? BuyItem(myId, item)
                      : UseItem(myId, item),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// La lista de ítems. En la tienda salen todos con su precio; en la mochila,
/// solo los que tienes y los que activaste para tu tirada.
class ItemList extends StatelessWidget {
  const ItemList({
    super.key,
    required this.player,
    required this.mode,
    required this.problemFor,
    required this.onPressed,
  });

  final PlayerState player;
  final ItemsMode mode;

  /// Por qué no se puede comprar o usar el ítem, o null si se puede.
  final String? Function(ShopItem item) problemFor;
  final void Function(ShopItem item) onPressed;

  @override
  Widget build(BuildContext context) {
    final items = mode == ItemsMode.shop
        ? ShopItem.values
        : [
            for (final item in ShopItem.values)
              if (player.itemCount(item) > 0) item,
          ];
    final active = player.activeItems;
    return ListView(
      shrinkWrap: true,
      children: [
        if (mode == ItemsMode.backpack && items.isEmpty && active.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tu mochila está vacía. Compra ítems en las tiendas del mapa.',
              textAlign: TextAlign.center,
            ),
          ),
        if (mode == ItemsMode.backpack && active.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Activo para tu tirada: '
              '${active.map((item) => item.title).join(', ')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        for (final item in items) _row(item),
      ],
    );
  }

  Widget _row(ShopItem item) {
    final problem = problemFor(item);
    final count = player.itemCount(item);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(itemIcon(item), color: AppColors.tileShop),
      title: Text(
        count > 0 ? '${item.title} (x$count)' : item.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(problem ?? item.description),
      trailing: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: AppColors.authAccent),
        onPressed: problem == null ? () => onPressed(item) : null,
        child: Text(mode == ItemsMode.shop ? '${item.price}' : 'Usar'),
      ),
    );
  }
}
