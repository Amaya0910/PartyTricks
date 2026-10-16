import 'package:flutter/material.dart';
import 'package:party_tricks/models/play_option.dart';
import 'package:party_tricks/widgets/play_menu_dialog.dart';
import 'package:party_tricks/widgets/player_header.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Pantalla de inicio. El fondo lo pone MainShellScreen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _onPlayPressed(BuildContext context) async {
    final option = await PlayMenuDialog.show(context);
    if (option == null || !context.mounted) return;

    // Provisional: se conectará a las salas en feature/rooms-lobby.
    final text = switch (option) {
      PlayOption.createParty => 'Crear party: próximamente',
      PlayOption.joinParty => 'Unirse a party: próximamente',
      PlayOption.randomGame => 'Juego random: próximamente',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Datos de prueba; luego vendrán del perfil del jugador.
        const PlayerHeader(username: 'Tay_pro32', coins: 999, diamonds: 999),
        // Reemplazar por el personaje armado con los cosméticos.
        const Expanded(
          child: Center(
            child: Icon(Icons.face, size: 200, color: AppColors.placeholderIcon),
          ),
        ),
        // SafeArea inferior: también deja espacio para la barra de navegación.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 0, 48, 24),
            child: _PlayButton(onPressed: () => _onPlayPressed(context)),
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});

  final VoidCallback onPressed;

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