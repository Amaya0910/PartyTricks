import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Presencia en las salas: si el jugador está conectado y desde cuándo no.
abstract class PresenceService {
  /// Mientras dure, marca al jugador conectado en la sala. Si pierde la
  /// conexión, el servidor lo marca desconectado solo; al volver la conexión
  /// se marca conectado de nuevo. Devuelve una función para dejar de seguir.
  void Function() track(String roomId, String uid);

  /// La hora del servidor. Es la que hay que comparar con `lastSeen`.
  DateTime serverNow();
}

/// Presencia con Realtime Database:
/// - `.info/connected` avisa cuando se cae o vuelve la conexión.
/// - `onDisconnect` deja guardado en el servidor lo que pasa si se cae:
///   `connected: false` y `lastSeen` con la hora del servidor.
class FirebasePresenceService implements PresenceService {
  FirebasePresenceService(this._db) {
    _db.ref('.info/serverTimeOffset').onValue.listen((event) {
      _offsetMs = (event.snapshot.value as num?)?.toInt() ?? 0;
    });
  }

  final FirebaseDatabase _db;
  int _offsetMs = 0;

  @override
  DateTime serverNow() => DateTime.now().add(Duration(milliseconds: _offsetMs));

  @override
  void Function() track(String roomId, String uid) {
    final me = _db.ref('rooms/$roomId/players/$uid');
    final subscription = _db.ref('.info/connected').onValue.listen((event) {
      if (event.snapshot.value != true) return;
      unawaited(_markOnline(me));
    });
    return subscription.cancel;
  }

  Future<void> _markOnline(DatabaseReference me) async {
    try {
      // Primero lo que hará el servidor si se cae, después marcarse
      // conectado: así no queda "conectado" para siempre.
      await me.onDisconnect().update({
        'connected': false,
        'lastSeen': ServerValue.timestamp,
      });
      await me.update({'connected': true, 'lastSeen': ServerValue.timestamp});
    } on FirebaseException catch (error) {
      // Ya no está en la sala (salió o la borraron): las reglas no lo dejan
      // volver a crearse y no hay nada que marcar.
      debugPrint('Presencia: ${error.message}');
    }
  }
}
