import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/character_look_controller.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';

/// Espacio de un jugador en la sala de espera: recuadro verde con su
/// personaje real respirando (con su ropa, cabello y foto de la cara) y su
/// nombre debajo. Si [player] es null, es un espacio libre.
///
/// El aspecto propio sale del vestuario; el de los demás, de su perfil
/// público. Mientras llega se ve el de quien no ha elegido nada.
class PlayerSlot extends ConsumerWidget {
  const PlayerSlot({
    super.key,
    this.player,
    this.isMe = false,
    this.isHost = false,
  });

  final RoomPlayer? player;
  final bool isMe;
  final bool isHost;

  /// Parte del recuadro que ocupa el personaje.
  static const _characterShare = 0.95;

  /// Ancho entre alto del lienzo del personaje (512 x 968).
  static const _canvasRatio = 512 / 968;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = this.player;
    final CharacterLook? look = player == null
        ? null
        : isMe
        ? ref.watch(characterLookProvider)
        : ref.watch(publicProfileProvider(player.uid)).value?.look ??
              CharacterLook.standard;
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.avatarBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slotBorder, width: 2),
            ),
            child: look == null
                ? null
                : Stack(
                    children: [
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final height = min(
                              constraints.maxHeight * _characterShare,
                              constraints.maxWidth *
                                  _characterShare /
                                  _canvasRatio,
                            );
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                height: height,
                                child: AnimatedCharacter.fromLook(look),
                              ),
                            );
                          },
                        ),
                      ),
                      if (isHost)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.star,
                            size: 20,
                            color: AppColors.coin,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 18,
          child: player == null
              ? null
              : Text(
                  isMe ? '${player.username}(tú)' : player.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
