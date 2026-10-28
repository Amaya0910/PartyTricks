import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/room_controller.dart';
import 'package:party_tricks/models/play_option.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/screens/lobby_screen.dart';
import 'package:party_tricks/screens/settings_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/rooms/room_service.dart';
import 'package:party_tricks/widgets/create_room_dialog.dart';
import 'package:party_tricks/widgets/join_code_dialog.dart';
import 'package:party_tricks/widgets/play_menu_dialog.dart';
import 'package:party_tricks/widgets/player_header.dart';
import 'package:party_tricks/widgets/verify_email_banner.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Pantalla de inicio. El fondo lo pone MainShellScreen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _onPlayPressed(BuildContext context, WidgetRef ref) async {
    final option = await PlayMenuDialog.show(context);
    if (option == null || !context.mounted) return;

    final rooms = ref.read(roomControllerProvider.notifier);
    try {
      final Room? room;
      switch (option) {
        case PlayOption.createParty:
          final settings = await CreateRoomDialog.show(context);
          if (settings == null) return;
          room = await rooms.create(settings);
        case PlayOption.joinParty:
          final code = await JoinCodeDialog.show(context);
          if (code == null) return;
          room = await rooms.joinByCode(code);
        case PlayOption.randomGame:
          room = await rooms.joinRandom();
      }
      if (!context.mounted) return;
      if (room == null) {
        _showMessage(context, 'No hay salas públicas libres, crea una');
        return;
      }
      await Navigator.of(context).push(LobbyScreen.route(room.id));
    } on RoomException catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Algo salió mal, intenta otra vez');
      }
    }
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(roomControllerProvider);
    // El perfil del jugador con la sesión iniciada (null solo un instante,
    // mientras llega de Firebase).
    final profile = ref.watch(userProfileProvider).value;

    return Column(
      children: [
        PlayerHeader(
          username: profile?.username ?? '',
          coins: profile?.coins ?? 0,
          diamonds: profile?.diamonds ?? 0,
          onAvatarTap: () => Navigator.of(context).push(SettingsScreen.route()),
        ),
        const VerifyEmailBanner(),
        // Reemplazar por el personaje armado con los cosméticos.
        const Expanded(
          child: Center(
            child: Icon(
              Icons.face,
              size: 200,
              color: AppColors.placeholderIcon,
            ),
          ),
        ),
        // SafeArea inferior: también deja espacio para la barra de navegación.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 0, 48, 24),
            child: _PlayButton(
              onPressed: loading ? null : () => _onPlayPressed(context, ref),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});

  /// Null mientras se crea o se busca la sala.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        backgroundColor: AppColors.blueLight,
        foregroundColor: AppColors.blueStrong,
        side: const BorderSide(color: AppColors.blueStrong, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Jugar',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Icon(Icons.diamond, size: 32),
        ],
      ),
    );
  }
}