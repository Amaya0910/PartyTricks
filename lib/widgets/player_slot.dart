import 'package:flutter/material.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Espacio de un jugador en la sala de espera: recuadro verde con su foto
/// y su nombre debajo. Si [player] es null, es un espacio libre.
class PlayerSlot extends StatelessWidget {
  const PlayerSlot({
    super.key,
    this.player,
    this.isMe = false,
    this.isHost = false,
  });

  final RoomPlayer? player;
  final bool isMe;
  final bool isHost;

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
                      Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.8,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _Avatar(photoUrl: player.photoUrl),
                          ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final photoUrl = this.photoUrl;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.blueLight,
        border: Border.all(color: AppColors.tileBorder, width: 2),
      ),
      child: ClipOval(
        child: photoUrl == null || photoUrl.isEmpty
            ? const _FallbackIcon()
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                // Si la foto no carga, se ve el ícono en vez de un error.
                errorBuilder: (_, _, _) => const _FallbackIcon(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const _FallbackIcon(),
              ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      child: Icon(Icons.person, color: AppColors.blueStrong),
    );
  }
}