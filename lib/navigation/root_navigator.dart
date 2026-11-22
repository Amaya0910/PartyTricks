import 'package:flutter/widgets.dart';

/// El navegador principal de la app. Sirve para abrir pantallas desde donde
/// no hay un contexto a mano, por ejemplo al tocar una notificación.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
