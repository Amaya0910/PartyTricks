import 'package:flutter/material.dart';
import 'package:party_tricks/models/play_option.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Menú emergente de "Jugar". Devuelve la opción elegida (o null si se cierra).
class PlayMenuDialog extends StatelessWidget {
  const PlayMenuDialog({super.key});

  static Future<PlayOption?> show(BuildContext context) {
    return showDialog<PlayOption>(
      context: context,
      builder: (_) => const PlayMenuDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionButton(
              label: 'Crear Party',
              option: PlayOption.createParty,
            ),
            const SizedBox(height: 16),
            _OptionButton(
              label: 'Unirse a Party',
              option: PlayOption.joinParty,
            ),
            const SizedBox(height: 16),
            _OptionButton(
              label: 'Juego Random',
              option: PlayOption.randomGame,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.option});

  final String label;
  final PlayOption option;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        backgroundColor: AppColors.menuButton,
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      onPressed: () => Navigator.of(context).pop(option),
      child: Text(label),
    );
  }
}