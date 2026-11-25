import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Vibraciones cortas que acompañan a la interfaz. Los widgets piden "qué
/// pasó" (un toque, un premio, un error) y no saben cómo vibra el celular.
abstract class Haptics {
  const Haptics();

  /// Se presionó un botón.
  void tap();

  /// Se eligió algo de una lista (pestaña, color, categoría).
  void select();

  /// Algo salió bien (premio, compra).
  void success();

  /// Algo salió mal (contraseña incorrecta, código inválido).
  void error();
}

/// Vibra con el motor del celular.
class DeviceHaptics extends Haptics {
  const DeviceHaptics();

  @override
  void tap() => HapticFeedback.lightImpact();

  @override
  void select() => HapticFeedback.selectionClick();

  @override
  void success() => HapticFeedback.mediumImpact();

  @override
  void error() => HapticFeedback.heavyImpact();
}

/// No vibra: cuando el jugador apagó la vibración y en las pruebas.
class SilentHaptics extends Haptics {
  const SilentHaptics();

  @override
  void tap() {}

  @override
  void select() {}

  @override
  void success() {}

  @override
  void error() {}
}

/// Entrega a los widgets de la app qué [Haptics] usar. Sin uno arriba en el
/// árbol, no vibra nada.
class HapticsScope extends InheritedWidget {
  const HapticsScope({super.key, required this.haptics, required super.child});

  final Haptics haptics;

  static Haptics of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HapticsScope>()?.haptics ??
      const SilentHaptics();

  @override
  bool updateShouldNotify(HapticsScope oldWidget) =>
      haptics.runtimeType != oldWidget.haptics.runtimeType;
}
