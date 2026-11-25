import 'package:flutter/material.dart';
import 'package:party_tricks/models/play_option.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/fx/chunky_button.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';

/// Menú emergente de "Jugar". Devuelve la opción elegida (o null si se cierra).
///
/// Usa la misma tarjeta que el resto de los diálogos (`DialogCard`): fondo
/// desenfocado, borde y cabecera azules. Los botones tienen relieve y entran
/// uno detrás de otro.
class PlayMenuDialog extends StatelessWidget {
  const PlayMenuDialog({super.key});

  static const title = '¡A la party!';

  static Future<PlayOption?> show(BuildContext context) {
    return showBlurredDialog<PlayOption>(
      context,
      builder: (_) => const PlayMenuDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const options = [
      _OptionButton(
        label: 'Crear Party',
        icon: Icons.celebration_rounded,
        option: PlayOption.createParty,
      ),
      _OptionButton(
        label: 'Unirse a Party',
        icon: Icons.vpn_key_rounded,
        option: PlayOption.joinParty,
      ),
      _OptionButton(
        label: 'Juego Random',
        icon: Icons.shuffle_rounded,
        option: PlayOption.randomGame,
      ),
    ];
    return DialogCard(
      title: title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, option) in options.indexed) ...[
              if (index > 0) const SizedBox(height: 12),
              PopIn.staggered(
                index: index,
                base: const Duration(milliseconds: 120),
                from: const Offset(0, 0.4),
                child: option,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Botón azul con relieve, con su ícono en una burbuja y su título.
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.icon,
    required this.option,
  });

  final String label;
  final IconData icon;
  final PlayOption option;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: AppColors.authAccent,
      edgeColor: AppColors.headerBorder,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onPressed: () => Navigator.of(context).pop(option),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.headerPanel,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
                shadows: [
                  Shadow(color: AppColors.headerBorder, offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.white),
        ],
      ),
    );
  }
}
