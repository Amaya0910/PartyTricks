import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/app_background.dart';
import 'package:party_tricks/widgets/fx/idle_motion.dart';
import 'package:party_tricks/widgets/fx/party_button.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';
import 'package:party_tricks/widgets/party_panel.dart';

/// Lo que ve quien se queda solo en la partida: todos los demás salieron o
/// se desconectaron (diseno_juego.md, sección 13). No da premios ni lo pasa
/// a otra sala: solo lo deja volver al menú.
class NoPlayersLeftView extends StatelessWidget {
  const NoPlayersLeftView({super.key, required this.onExit});

  static const title = '¡Se acabó la fiesta!';
  static const message =
      'Lo sentimos, no quedan jugadores :(\n'
      'Todos se fueron de la party y te dejaron solo con el confeti.';
  static const note =
      'Esta partida ya no da premios. '
      '¡Invita a tus amigos y arma otra fiesta!';
  static const exitLabel = 'Regresar a menú';

  /// Saca al jugador de la sala y lo lleva al menú.
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.screenBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: PopIn(
                    startScale: 0.7,
                    child: PartyPanel(
                      padding: const EdgeInsets.all(24),
                      radius: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Floating(
                            child: Icon(
                              Icons.celebration_outlined,
                              size: 72,
                              color: AppColors.authAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.authAccent,
                              shadows: [
                                Shadow(
                                  color: AppColors.headerBorder,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            note,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          PartyButton(label: exitLabel, onPressed: onExit),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
