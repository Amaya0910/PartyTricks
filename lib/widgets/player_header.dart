import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/pressable_scale.dart';
import 'package:party_tricks/widgets/stat_pill.dart';

/// Cabecera con el avatar, el nombre y las monedas/diamantes del jugador.
/// No conoce Riverpod: recibe los datos ya listos.
class PlayerHeader extends StatelessWidget {
  const PlayerHeader({
    super.key,
    required this.username,
    required this.coins,
    required this.diamonds,
    this.avatar,
    this.onAvatarTap,
  });

  final String username;
  final int coins;
  final int diamonds;

  /// La foto de perfil (la cabeza del personaje). Si es null, un ícono.
  final Widget? avatar;

  /// Abre la pantalla de Ajustes (la llave del mockup).
  final VoidCallback? onAvatarTap;

  /// Desenfoque del fondo detrás de toda la cabecera.
  static const double _headerBlur = 6;

  /// Desenfoque del fondo detrás del cuadro interno (más fuerte).
  static const double _panelBlur = 14;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _headerBlur, sigmaY: _headerBlur),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.headerBackground,
            border: Border(
              bottom: BorderSide(color: AppColors.headerBorder, width: 3),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  PressableScale(
                    onTap: onAvatarTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        avatar ??
                            const CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.avatarBackground,
                              child: Icon(Icons.person, size: 36),
                            ),
                        // La llave de Ajustes, en una burbuja para que se vea
                        // como un botón.
                        Positioned(
                          left: -6,
                          bottom: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.headerBorder,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.pillShadow,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.build,
                              size: 16,
                              color: AppColors.headerBorder,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _panelBlur,
                          sigmaY: _panelBlur,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: AppColors.headerPanel,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.headerBorder,
                                      offset: Offset(0, 2),
                                      blurRadius: 2,
                                    ),
                                  ],
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
