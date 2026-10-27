import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/profile_avatar.dart';

/// Lista de amigos con casillas para invitarlos a la party. Devuelve los
/// uid elegidos, o null si se cierra.
///
/// [exclude] son los que ya están en la sala: no aparecen en la lista.
class InviteFriendsDialog extends ConsumerStatefulWidget {
  const InviteFriendsDialog({super.key, this.exclude = const {}});

  final Set<String> exclude;

  static Future<List<String>?> show(
    BuildContext context, {
    Set<String> exclude = const {},
  }) {
    return showBlurredDialog<List<String>>(
      context,
      builder: (_) => InviteFriendsDialog(exclude: exclude),
    );
  }

  @override
  ConsumerState<InviteFriendsDialog> createState() =>
      _InviteFriendsDialogState();
}

class _InviteFriendsDialogState extends ConsumerState<InviteFriendsDialog> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final friends = ref
        .watch(friendUidsProvider)
        .where((uid) => !widget.exclude.contains(uid))
        .toList();

    return DialogCard(
      title: 'Invitar amigos',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (friends.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aún no tienes amigos para invitar. Agrégalos con su '
                  'código en la pestaña Amigos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.authText),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final uid in friends)
                      _FriendCheck(
                        uid: uid,
                        checked: _selected.contains(uid),
                        onChanged: (checked) => setState(() {
                          checked ? _selected.add(uid) : _selected.remove(uid);
                        }),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accept,
                ),
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_selected.toList()),
                child: Text(
                  _selected.isEmpty
                      ? 'Elige a quién invitar'
                      : 'Invitar (${_selected.length})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCheck extends ConsumerWidget {
  const _FriendCheck({
    required this.uid,
    required this.checked,
    required this.onChanged,
  });

  final String uid;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(uid)).value;
    return CheckboxListTile(
      value: checked,
      onChanged: (value) => onChanged(value ?? false),
      secondary: ProfileAvatar(photoUrl: profile?.photoUrl, size: 36),
      title: Text(
        profile?.username ?? 'Jugador',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      activeColor: AppColors.friendsAccent,
      dense: true,
    );
  }
}
