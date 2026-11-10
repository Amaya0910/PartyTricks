import 'package:flutter/foundation.dart';

/// En la versión release la app no escribe nada en la consola (H-09).
///
/// `debugPrint` también imprime en release: sale en Logcat (Android) y en la
/// consola de Xcode, donde lo puede leer cualquiera con el celular conectado.
/// La app lo usa para los errores de Firebase, que traen rutas con uid y
/// mensajes internos. Se llama al empezar `main`.
void silenceDebugLogsInRelease({bool isRelease = kReleaseMode}) {
  if (!isRelease) return;
  debugPrint = (String? message, {int? wrapWidth}) {};
}
