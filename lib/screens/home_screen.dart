import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/character_look_controller.dart';
import 'package:party_tricks/controllers/room_controller.dart';
import 'package:party_tricks/models/play_option.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/screens/lobby_screen.dart';
import 'package:party_tricks/screens/settings_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/map/map_providers.dart';
import 'package:party_tricks/services/rooms/room_service.dart';
import 'package:party_tricks/widgets/active_game_banner.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/create_room_dialog.dart';
import 'package:party_tricks/widgets/fx/chunky_button.dart';
import 'package:party_tricks/widgets/fx/idle_motion.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';
import 'package:party_tricks/widgets/fx/shine_sweep.dart';
import 'package:party_tricks/widgets/join_code_dialog.dart';
import 'package:party_tricks/widgets/play_menu_dialog.dart';
import 'package:party_tricks/widgets/my_avatar.dart';
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
    // Empieza a leer qué mapas están encendidos, para que al abrir "Crear
    // sala" ya esté la lista.
    ref.listen(remoteMapConfigProvider, (_, _) {});
    // El perfil del jugador con la sesión iniciada (null solo un instante,
    // mientras llega de Firebase).
    final profile = ref.watch(userProfileProvider).value;

    return Column(
      children: [
        PopIn(
          from: const Offset(0, -0.6),
          startScale: 1,
          child: PlayerHeader(
            username: profile?.username ?? '',
            coins: profile?.coins ?? 0,
            diamonds: profile?.diamonds ?? 0,
            avatar: const MyAvatar(size: 64),
            onAvatarTap: () =>
                Navigator.of(context).push(SettingsScreen.route()),
          ),
        ),
        const VerifyEmailBanner(),
        const ActiveGameBanner(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PopIn(
                delay: const Duration(milliseconds: 150),
                startScale: 0.6,
                child: AnimatedCharacter.fromLook(
                  ref.watch(characterLookProvider),
                ),
              ),
            ),
          ),
        ),
        // SafeArea inferior: también deja espacio para la barra de navegación.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 0, 48, 24),
            child: PopIn(
              delay: const Duration(milliseconds: 300),
              from: const Offset(0, 0.8),
              child: _PlayButton(
                onPressed: loading ? null : () => _onPlayPressed(context, ref),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// El botón principal: con relieve, respira y lo cruza un destello para que
/// se note que es lo primero que hay que tocar.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});

  /// Null mientras se crea o se busca la sala.
  final VoidCallback? onPressed;

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final button = ChunkyButton(
      color: AppColors.blueLight,
      edgeColor: AppColors.blueStrong,
      borderColor: AppColors.blueStrong,
      radius: _radius,
      depth: 7,
      padding: const EdgeInsets.symmetric(vertical: 10),
      onPressed: onPressed,
      semanticLabel: 'Jugar',
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Jugar',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.blueStrong,
              letterSpacing: 1,
              // Relieve blanco debajo de las letras, como en los juegos.
              shadows: [Shadow(color: AppColors.white, offset: Offset(0, 2))],
            ),
          ),
          SizedBox(width: 10),
          Wobble(
            child: Icon(Icons.diamond, size: 34, color: AppColors.blueStrong),
          ),
        ],
      ),
    );

    // Mientras carga no respira ni brilla: así se nota que está ocupado.
    if (onPressed == null) return button;
    return Breathing(
      child: ShineSweep(radius: _radius, child: button),
    );
  }
}
