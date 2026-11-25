import 'package:flutter/material.dart';

/// Al abrir una pantalla, entra creciendo un poco y aparece; al cerrarla,
/// sale al revés. Es la transición de toda la app (ver `AppTheme`).
class PartyPageTransitionsBuilder extends PageTransitionsBuilder {
  const PartyPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    // La pantalla de atrás se encoge un poco mientras entra la nueva.
    final behind = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut),
    );
    return ScaleTransition(
      scale: behind,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(enter),
          child: child,
        ),
      ),
    );
  }
}
