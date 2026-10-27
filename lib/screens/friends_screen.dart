import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/friends_controller.dart';
import 'package:party_tricks/controllers/navigation_controller.dart';
import 'package:party_tricks/models/app_section.dart';
import 'package:party_tricks/screens/chat_view.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/social/chat_format.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/friend_request_tile.dart';
import 'package:party_tricks/widgets/friend_tile.dart';
import 'package:party_tricks/widgets/join_code_dialog.dart';

/// Pestaña Amigos: la tarjeta "Tus amigos" con las solicitudes, la lista y
/// el botón "+"; o el chat con un amigo, en la misma tarjeta (como en el
/// mockup). El fondo lo pone MainShellScreen.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(currentUidProvider);
    final openChat = ref.watch(openChatProvider);
    final visible =
        ref.watch(navigationControllerProvider) == AppSection.friends;

    // El botón atrás del celular cierra el chat antes de salir de la app
    // (solo si se está viendo esta pestaña).
    return PopScope(
      canPop: openChat == null || !visible,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(openChatProvider.notifier).close();
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: _Card(
            child: myUid == null
                ? const Center(child: CircularProgressIndicator())
                : openChat == null
                ? _FriendsList(myUid: myUid)
                : ChatView(friendUid: openChat, myUid: myUid),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta blanca con el borde azul oscuro del mockup.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  static const double _radius = 24;
  static const double _border = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColors.friendsBorder, width: _border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - _border),
        child: child,
      ),
    );
  }
}

class _FriendsList extends ConsumerWidget {
  const _FriendsList({required this.myUid});

  final String myUid;

  void _show(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addFriend(BuildContext context, WidgetRef ref) async {
    final friends = ref.read(friendsControllerProvider);
    final code = await JoinCodeDialog.show(
      context,
      title: 'Agregar amigo',
      label: 'Código de tu amigo',
    );
    if (code == null) return;
    try {
      final message = await friends.addByCode(code);
      if (context.mounted) _show(context, message);
    } on SocialException catch (error) {
      if (context.mounted) _show(context, error.message);
    }
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on SocialException catch (error) {
      if (context.mounted) _show(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(friendsSectionsProvider);
    final loading = ref.watch(friendshipsProvider).isLoading;
    final chats = ref.watch(chatsProvider).value ?? const {};
    final friends = ref.read(friendsControllerProvider);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Title(),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      // Espacio abajo para que el botón "+" no tape a nadie.
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      children: [
                        const _MyCode(),
                        if (sections.isEmpty) const _Empty(),
                        if (sections.incoming.isNotEmpty) ...[
                          _SectionLabel(
                            'Solicitudes (${sections.incoming.length})',
                          ),
                          for (final request in sections.incoming)
                            FriendRequestTile.incoming(
                              otherUid: request.otherOf(myUid),
                              onAccept: () => _run(
                                context,
                                () => friends.accept(request),
                              ),
                              onReject: () => _run(
                                context,
                                () => friends.remove(request),
                              ),
                            ),
                        ],
                        if (sections.friends.isNotEmpty) ...[
                          if (sections.incoming.isNotEmpty)
                            const _SectionLabel('Amigos'),
                          for (final friend in sections.friends)
                            FriendTile(
                              friendUid: friend.otherOf(myUid),
                              myUid: myUid,
                              chat: chats[friend.id],
                              onTap: () => ref
                                  .read(openChatProvider.notifier)
                                  .open(friend.otherOf(myUid)),
                            ),
                        ],
                        if (sections.outgoing.isNotEmpty) ...[
                          const _SectionLabel('Enviadas'),
                          for (final request in sections.outgoing)
                            FriendRequestTile.outgoing(
                              otherUid: request.otherOf(myUid),
                              onCancel: () => _run(
                                context,
                                () => friends.remove(request),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _AddButton(onPressed: () => _addFriend(context, ref)),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.friendsAccent,
        boxShadow: [
          BoxShadow(
            color: AppColors.headerBorder,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        'Tus amigos',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// "Tu código: ABC-234" con botón para copiarlo y compartirlo.
class _MyCode extends ConsumerWidget {
  const _MyCode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(userProfileProvider).value?.friendCode ?? '';
    if (code.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: Text(
            'Tu código: ${ChatFormat.roomCode(code)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.authText,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Copiar código',
          icon: const Icon(Icons.copy, color: AppColors.friendsAccent),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: code));
            messenger.showSnackBar(
              const SnackBar(content: Text('Código copiado')),
            );
          },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.friendsBorder,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Text(
        'Aún no tienes amigos.\nToca + y escribe el código de tu amigo.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: AppColors.authHint),
      ),
    );
  }
}

/// Botón cuadrado "+" del mockup.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.friendsAccent,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: const SizedBox.square(
          dimension: 72,
          child: Icon(Icons.add, size: 48, color: AppColors.white),
        ),
      ),
    );
  }
}
