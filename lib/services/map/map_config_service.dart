import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:party_tricks/services/map/remote_map_config.dart';

/// De dónde sale la [RemoteMapConfig].
abstract interface class MapConfigService {
  /// La configuración en vivo: cada cambio en Firebase llega solo.
  Stream<RemoteMapConfig> watch();
}

/// Lee `config/maps` de Realtime Database con un solo listener.
///
/// El SDK guarda el último valor en memoria mientras el listener vive, y
/// solo baja los cambios: es un nodo de pocos bytes, así que cuesta casi
/// nada. No se guarda en disco a propósito: si al abrir la app no hay
/// conexión, se muestran solo los mapas de respaldo (ver
/// [RemoteMapConfig.unavailable]).
class FirebaseMapConfigService implements MapConfigService {
  const FirebaseMapConfigService(this._db);

  static const path = 'config/maps';

  final FirebaseDatabase _db;

  @override
  Stream<RemoteMapConfig> watch() => _db
      .ref(path)
      .onValue
      .map((event) => RemoteMapConfig.fromValue(event.snapshot.value));
}

/// [source] sin errores ni esperas largas:
///
/// - Si no llega nada en [timeout], emite [RemoteMapConfig.unavailable]
///   (y sigue escuchando: si Firebase responde después, se usa).
/// - Si falla (sin permiso, sin sesión), emite
///   [RemoteMapConfig.unavailable] en vez del error.
Stream<RemoteMapConfig> withFallback(
  Stream<RemoteMapConfig> source, {
  Duration timeout = const Duration(seconds: 5),
}) {
  late final StreamController<RemoteMapConfig> controller;
  StreamSubscription<RemoteMapConfig>? subscription;
  Timer? timer;

  void fallBack(String reason) {
    debugPrint('Mapas remotos: $reason; solo se muestran los de respaldo');
    controller.add(RemoteMapConfig.unavailable);
  }

  controller = StreamController<RemoteMapConfig>(
    onListen: () {
      timer = Timer(timeout, () => fallBack('Firebase no respondió'));
      subscription = source.listen(
        (config) {
          timer?.cancel();
          controller.add(config);
        },
        onError: (Object error) {
          timer?.cancel();
          fallBack('no se pudo leer la configuración ($error)');
        },
        onDone: () {
          timer?.cancel();
          controller.close();
        },
      );
    },
    onCancel: () {
      timer?.cancel();
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
