import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/profile_avatar.dart';

/// Una solicitud de amistad. Si es recibida, tiene Aceptar y Rechazar; si es
/// enviada, dice "Pendiente" y se puede cancelar.
class FriendRequestTile extends ConsumerWidget {
  const FriendRequestTile.incoming({
    super.key,
    required this.otherUid,
    required VoidCallback this.onAccept,
    required this.onReject,
  });

  const FriendRequestTile.outgoing({
    super.key,
    required this.otherUid,
    required VoidCallback onCancel,
  }) : onAccept = null,
       onReject = onCancel;

  final String otherUid;

  /// Null en las solicitudes enviadas.
  final VoidCallback? onAccept;

  /// Rechazar (recibida) o cancelar (enviada).
  final VoidCallback onReject;

  bool get _incoming => onAccept != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(otherUid)).value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ProfileAvatar(photoUrl: profile?.photoUrl, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.username ?? 'Jugador',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _incoming ? 'Quiere ser tu amigo' : 'Pendiente',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.authHint,
                  ),
                ),
              ],
            ),
          ),
          if (_incoming)
            IconButton(
              tooltip: 'Aceptar',
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle, color: AppColors.accept),
            ),
          IconButton(
            tooltip: _incoming ? 'Rechazar' : 'Cancelar solicitud',
            onPressed: onReject,
            icon: const Icon(Icons.cancel, color: AppColors.reject),
          ),
        ],
      ),
    );
  }
}
