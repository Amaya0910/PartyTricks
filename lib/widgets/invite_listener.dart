import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/invite_controller.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/models/social/party_invite.dart';
import 'package:party_tricks/screens/invite_join.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/services/social/chat_format.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';

/// Muestra un aviso cuando un amigo te invita a su party. No dibuja nada
/// más: solo envuelve a [child].
///
/// El aviso solo sale si se ve el menú principal: no interrumpe la sala de
/// espera ni una partida (esas pantallas quedan encima). Si la party ya
/// empezó o se cerró, el aviso no sale y se marca como visto.
class InviteListener extends ConsumerStatefulWidget {
  const InviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InviteListener> createState() => _InviteListenerState();
}

class _InviteListenerState extends ConsumerState<InviteListener> {
  /// Para mostrar un aviso a la vez.
  bool _showing = false;

  bool get _onMainMenu => ModalRoute.of(context)?.isCurrent ?? true;

  Future<void> _showNext(List<PartyInvite> invites) async {
    if (_showing || invites.isEmpty || !mounted || !_onMainMenu) return;
    _showing = true;
    final invite = invites.first;
    final controller = ref.read(inviteControllerProvider);
    try {
      final room = await ref
          .read(roomServiceProvider)
          .watchRoom(invite.roomId)
          .first;
      await controller.markSeen(invite.id);
      if (!mounted || room?.status != RoomStatus.waiting) return;

      final join = await showBlurredDialog<bool>(
        context,
        builder: (_) => _InviteDialog(invite: invite),
      );
      if (join == true && mounted) {
        await joinPartyFromInvite(context, ref, invite.roomCode);
      }
    } catch (_) {
      // Si no se pudo revisar la sala, la invitación sigue en el chat.
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingInvitesProvider, (_, next) {
      final invites = next.value;
      if (invites != null) _showNext(invites);
    });
    return widget.child;
  }
}

class _InviteDialog extends StatelessWidget {
  const _InviteDialog({required this.invite});

  final PartyInvite invite;

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      title: '¡Te invitaron!',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${invite.fromName} te invitó a su party\n'
              'Código ${ChatFormat.roomCode(invite.roomCode)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, color: AppColors.authText),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accept),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unirse'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
          ],
        ),
      ),
    );
  }
}
