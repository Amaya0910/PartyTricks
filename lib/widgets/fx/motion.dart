import 'package:flutter/widgets.dart';

/// Reglas comunes de movimiento de la interfaz.
///
/// Todas las animaciones decorativas (pulsos, brillos, rebotes) preguntan
/// aquí si deben moverse, para respetar la opción del celular de reducir las
/// animaciones.
abstract final class Motion {
  /// True si el sistema pidió quitar las animaciones.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Duración de las entradas (aparecer en pantalla).
  static const Duration entrance = Duration(milliseconds: 520);

  /// Separación entre elementos que entran uno detrás de otro.
  static const Duration stagger = Duration(milliseconds: 70);

  /// Curva con rebote de las entradas y los botones.
  static const Curve pop = Curves.easeOutBack;
}
