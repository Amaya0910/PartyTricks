import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/screens/board_screen.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/chunky_button.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';

/// Si el jugador cerró la app con una partida en curso, le ofrece volver.
///
/// Solo aparece si la sala sigue existiendo, está en juego y el jugador
/// sigue en ella. Si la sala ya no existe, se olvida sola.
class ActiveGameBanner extends ConsumerWidget {
  const ActiveGameBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(activeGameProvider).value;
    final me = ref.watch(roomIdentityProvider).value;
    if (roomId == null || me == null) return const SizedBox.shrink();
    final roomAsync = ref.watch(roomProvider(roomId));
    if (roomAsync.isLoading) return const SizedBox.shrink();
    final room = roomAsync.value;
    final canRejoin =
        room != null &&
        room.status == RoomStatus.playing &&
        room.players.containsKey(me.uid);
    if (!canRejoin) {
      if (!roomAsync.hasError) {
        // La sala terminó o lo sacaron: ya no hay a dónde volver.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(roomServiceProvider)
              .setActiveGame(me.uid, null)
              .catchError((Object _) {});
        });
      }
      return const SizedBox.shrink();
    }
    return PopIn(
      from: const Offset(0, -0.4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Material(
          color: AppColors.boardPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.authAccent, width: 2),
          ),
          elevation: 3,
          shadowColor: AppColors.pillShadow,
          child: ListTile(
            leading: const Icon(
              Icons.sports_esports,
              color: AppColors.authAccent,
            ),
            title: const Text(
              'Tienes una partida en curso',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Tus monedas, ítems y posición te esperan.'),
            trailing: ChunkyButton(
              color: AppColors.authAccent,
              edgeColor: AppColors.headerBorder,
              radius: 14,
              depth: 4,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              onPressed: () => Navigator.of(context).push(
                BoardScreen.route(room.id, isHost: room.hostUid == me.uid),
              ),
              child: const Text(
                'Volver',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
