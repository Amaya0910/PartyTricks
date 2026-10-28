import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/chat_controller.dart';
import 'package:party_tricks/controllers/friends_controller.dart';
import 'package:party_tricks/controllers/moderation_controller.dart';
import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/screens/invite_join.dart';
import 'package:party_tricks/services/game_engine/experience_calculator.dart';
import 'package:party_tricks/services/social/pair_id.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/chat_bubble.dart';
import 'package:party_tricks/widgets/chat_input.dart';
import 'package:party_tricks/widgets/confirm_dialog.dart';
import 'package:party_tricks/widgets/level_pill.dart';
import 'package:party_tricks/widgets/profile_avatar.dart';
import 'package:party_tricks/widgets/report_dialog.dart';

/// Opciones del menú de la cabecera del chat.
enum _ChatAction { remove, block, report }

/// Chat con un amigo, dentro de la pestaña Amigos (como en el mockup):
/// cabecera con su foto, nombre y nivel; los mensajes; y el campo para
/// escribir. El menú ⋮ permite eliminar, bloquear y reportar.
class ChatView extends ConsumerWidget {
  const ChatView({super.key, required this.friendUid, required this.myUid});

  final String friendUid;
  final String myUid;

  void _show(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _send(BuildContext context, WidgetRef ref, String text) async {
    try {
      await ref
          .read(chatControllerProvider)
          .send(friendUid: friendUid, text: text);
      return true;
    } on SocialException catch (error) {
      if (context.mounted) _show(context, error.message);
      return false;
    }
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _ChatAction action,
    String name,
  ) async {
    // Se leen antes de esperar: al bloquear o eliminar, el chat se cierra.
    final moderation = ref.read(moderationControllerProvider);
    final friends = ref.read(friendsControllerProvider);
    final chats = ref.read(openChatProvider.notifier);
    try {
      switch (action) {
        case _ChatAction.remove:
          final friendship = ref
              .read(friendsSectionsProvider)
              .friends
              .where((f) => f.otherOf(myUid) == friendUid)
              .firstOrNull;
          if (friendship == null) return;
          final ok = await ConfirmDialog.show(
            context,
            title: 'Eliminar',
            message: '¿Eliminar a $name de tus amigos?',
            confirmLabel: 'Eliminar',
          );
          if (!ok) return;
          await friends.remove(friendship);
          chats.close();
        case _ChatAction.block:
          final ok = await ConfirmDialog.show(
            context,
            title: 'Bloquear',
            message:
                '$name dejará de ser tu amigo y ya no podrá escribirte, '
                'enviarte solicitudes ni invitarte.',
            confirmLabel: 'Bloquear',
          );
          if (!ok) return;
          await moderation.block(friendUid);
          chats.close();
          if (context.mounted) _show(context, 'Bloqueaste a $name.');
        case _ChatAction.report:
          final reason = await ReportDialog.show(context, name);
          if (reason == null) return;
          await moderation.report(friendUid, reason);
          if (context.mounted) {
            _show(context, 'Gracias. Un adulto revisará el reporte.');
          }
      }
    } on SocialException catch (error) {
      if (context.mounted) _show(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatId = PairId.of(myUid, friendUid);
    // Mientras el chat está abierto, todo lo que llega queda leído.
    ref.listen(chatMessagesProvider(chatId), (_, next) {
      if (next.hasValue) ref.read(chatControllerProvider).markRead(friendUid);
    });
    final profile = ref.watch(publicProfileProvider(friendUid)).value;
    final messages = ref.watch(chatMessagesProvider(chatId));
    final isFriend = ref.watch(friendUidsProvider).contains(friendUid);
    final now = ref.watch(clockProvider)();
    final name = profile?.username ?? 'Jugador';

    return Column(
      children: [
        _Header(
          profile: profile,
          onBack: ref.read(openChatProvider.notifier).close,
          onAction: (action) => _onAction(context, ref, action, name),
        ),
        Expanded(
          child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(
              child: Text('No se pudieron cargar los mensajes.'),
            ),
            data: (list) => list.isEmpty
                ? Center(
                    child: Text(
                      '¡Saluda a $name!',
                      style: const TextStyle(color: AppColors.authHint),
                    ),
                  )
                : ListView.builder(
                    // Al revés: los más nuevos quedan abajo, junto al campo.
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final message = list[list.length - 1 - index];
                      return ChatBubble(
                        message: message,
                        isMine: message.senderId == myUid,
                        now: now,
                        onJoin: (code) =>
                            joinPartyFromInvite(context, ref, code),
                      );
                    },
                  ),
          ),
        ),
        if (isFriend)
          ChatInput(onSend: (text) => _send(context, ref, text))
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Ya no son amigos.',
              style: TextStyle(color: AppColors.authHint),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.profile,
    required this.onBack,
    required this.onAction,
  });

  final PublicProfile? profile;
  final VoidCallback onBack;
  final ValueChanged<_ChatAction> onAction;

  static const _levels = ExperienceCalculator();

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    return Container(
      color: AppColors.chatHeader,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          ProfileAvatar(photoUrl: profile?.photoUrl, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              profile?.username ?? 'Jugador',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          if (profile != null)
            LevelPill(level: _levels.levelForXp(profile.experience)),
          PopupMenuButton<_ChatAction>(
            tooltip: 'Opciones',
            onSelected: onAction,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _ChatAction.remove,
                child: Text('Eliminar amigo'),
              ),
              PopupMenuItem(value: _ChatAction.block, child: Text('Bloquear')),
              PopupMenuItem(value: _ChatAction.report, child: Text('Reportar')),
            ],
          ),
        ],
      ),
    );
  }
}
