import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/loading_dots.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';
import 'package:party_tricks/widgets/liquid_progress_bar.dart';

/// Pantalla de carga: el dibujo de fondo y la barra en el centro.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Fondo_Carga.png',
            fit: BoxFit.cover,
            // Si falta la imagen, se ve un color liso en vez de un error.
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: AppColors.loadingFallback),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: PopIn(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LiquidProgressBar(progress: progress, height: 30),
                    const SizedBox(height: 14),
                    const LoadingDots(label: 'Cargando'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
