import 'package:flutter/material.dart';
import 'package:party_tricks/widgets/stat_pill.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Cabecera con el avatar, el nombre y las monedas/diamantes del jugador.
/// No conoce Riverpod: recibe los datos ya listos.
class PlayerHeader extends StatelessWidget {
  const PlayerHeader({
    super.key,
    required this.username,
    required this.coins,
    required this.diamonds,
    this.onAvatarTap,
  });

  final String username;
  final int coins;
  final int diamonds;

  /// Se usará para abrir la pantalla de ajustes (la llave del mockup).
  final VoidCallback? onAvatarTap;


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(bottom: BorderSide(color: AppColors.headerBorder, width: 3)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.avatarBackground,
                      // Reemplazar por el rostro del personaje.
                      child: Icon(Icons.person, size: 36),
                    ),
                    Positioned(
                      left: -4,
                      bottom: -4,
                      child: Icon(
                        Icons.build,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.headerPanel,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: StatPill(
                              icon: Icons.monetization_on,
                              color: AppColors.coin,
                              value: coins,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatPill(
                              icon: Icons.diamond,
                              color: AppColors.diamond,
                              value: diamonds,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}