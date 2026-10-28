import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/moderation_controller.dart';
import 'package:party_tricks/services/social/social_exception.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/profile_avatar.dart';

/// Jugadores bloqueados, con el botón Desbloquear (ver `decisiones.md`,
/// D-22). Desbloquear no los vuelve amigos: hay que enviar otra solicitud.
class BlockedPlayersScreen extends ConsumerWidget {
  const BlockedPlayersScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const BlockedPlayersScreen());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUidsProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Jugadores bloqueados'),
        backgroundColor: AppColors.settingsAccent,
        foregroundColor: AppColors.white,
      ),
      body: blocked.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('No se pudo cargar la lista. Revisa tu conexión.'),
        ),
        data: (uids) => uids.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No has bloqueado a nadie.',
                    style: TextStyle(fontSize: 16, color: AppColors.authHint),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [for (final uid in uids) _BlockedTile(uid: uid)],
              ),
      ),
    );
  }
}

class _BlockedTile extends ConsumerWidget {
  const _BlockedTile({required this.uid});

  final String uid;

  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(moderationControllerProvider).unblock(uid);
      messenger.showSnackBar(
        const SnackBar(content: Text('Jugador desbloqueado')),
      );
    } on SocialException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(uid)).value;
    return ListTile(
      leading: ProfileAvatar(photoUrl: profile?.photoUrl, size: 40),
      title: Text(profile?.username ?? 'Jugador'),
      trailing: TextButton(
        onPressed: () => _unblock(context, ref),
        child: const Text('Desbloquear'),
      ),
    );
  }
}
