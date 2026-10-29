import 'dart:math';

import 'package:flutter/material.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/party_character.dart';

/// Espacio de un jugador en la sala de espera: recuadro verde con su
/// personaje respirando (con su foto en la cara) y su nombre debajo. Si
/// [player] es null, es un espacio libre.
class PlayerSlot extends StatelessWidget {
  const PlayerSlot({
    super.key,
    this.player,
    this.color = AppColors.blueStrong,
    this.index = 0,
    this.isMe = false,
    this.isHost = false,
  });

  final RoomPlayer? player;

  /// Color de la ropa del personaje.
  final Color color;

  /// Lugar en la sala; desfasa la respiración de cada personaje.
  final int index;
  final bool isMe;
  final bool isHost;

  /// Parte del recuadro que ocupa el personaje.
  static const _characterShare = 0.9;

  @override
  Widget build(BuildContext context) {
    final player = this.player;
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
            child: player == null
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
                                  PartyCharacter.aspectRatio,
                            );
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: PartyCharacter(
                                color: color,
                                height: height,
                                photoUrl: player.photoUrl,
                                idle: true,
                                idlePhase: index * 0.37 % 1,
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
