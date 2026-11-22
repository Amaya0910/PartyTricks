import 'package:flutter/material.dart';
import 'package:party_tricks/models/play_option.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';

/// Menú emergente de "Jugar". Devuelve la opción elegida (o null si se cierra).
///
/// Usa la misma tarjeta que el resto de los diálogos (`DialogCard`): fondo
/// desenfocado, borde y cabecera azules, y botones con la sombra de las
/// píldoras de "Alista tu party".
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
    return const DialogCard(
      title: title,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionButton(
              label: 'Crear Party',
              icon: Icons.celebration_rounded,
              option: PlayOption.createParty,
            ),
            SizedBox(height: 14),
            _OptionButton(
              label: 'Unirse a Party',
              icon: Icons.vpn_key_rounded,
              option: PlayOption.joinParty,
            ),
            SizedBox(height: 14),
            _OptionButton(
              label: 'Juego Random',
              icon: Icons.shuffle_rounded,
              option: PlayOption.randomGame,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón azul en forma de píldora, con su ícono y su título.
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.icon,
    required this.option,
  });

  final String label;
  final IconData icon;
  final PlayOption option;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pillShadow,
            blurRadius: 3,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: AppColors.authAccent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(option),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(icon, size: 30, color: AppColors.white),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
