import 'package:flutter/material.dart';

/// El fondo de las pantallas del juego. Llena lo que tenga disponible y deja
/// las colinas ancladas abajo.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Fondo_Principal.png',
      fit: BoxFit.cover,
      alignment: Alignment.bottomCenter,
      // Si falta la imagen, se ve el color de la pantalla.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
