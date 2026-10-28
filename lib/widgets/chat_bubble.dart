import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/social/chat_message.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/services/social/chat_format.dart';
import 'package:party_tricks/services/social/invite_status.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Un mensaje del chat: los míos a la derecha en azul y los del amigo a la
/// izquierda en gris, con la hora debajo. Las invitaciones llevan el botón
/// para unirse.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.now,
    this.onJoin,
  });

  final ChatMessage message;
  final bool isMine;

  /// Para decidir si la hora lleva fecha.
  final DateTime now;

  /// Al tocar "Unirse" en una invitación (recibe el código de la sala).
  final ValueChanged<String>? onJoin;

  @override
  Widget build(BuildContext context) {
    final textColor = isMine ? AppColors.white : AppColors.authText;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: isMine ? AppColors.friendsAccent : AppColors.chatField,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMine ? 14 : 2),
              bottomRight: Radius.circular(isMine ? 2 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: TextStyle(fontSize: 15, color: textColor),
                ),
              ),
              if (message.isInvite && message.roomId != null)
                _InviteButton(
                  roomId: message.roomId!,
                  roomCode: message.roomCode ?? '',
                  // Quien invita no necesita unirse a su propia party.
                  onJoin: isMine ? null : onJoin,
                ),
              const SizedBox(height: 2),
              Text(
                ChatFormat.time(message.sentAt, now),
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de la invitación. Cambia según la sala: "Unirse", "La party ya
/// empezó" o "La party se cerró".
class _InviteButton extends ConsumerWidget {
  const _InviteButton({
    required this.roomId,
    required this.roomCode,
    required this.onJoin,
  });

  final String roomId;
  final String roomCode;
  final ValueChanged<String>? onJoin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider(roomId));
    final status = room.isLoading
        ? InviteStatus.loading
        : InviteStatus.of(room.value);
    final canJoin = status.canJoin && onJoin != null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accept,
            disabledBackgroundColor: AppColors.chatField,
          ),
          onPressed: canJoin ? () => onJoin!(roomCode) : null,
          child: Text(
            status.canJoin && onJoin == null
                ? 'Invitación enviada'
                : status.label,
          ),
        ),
      ),
    );
  }
}
