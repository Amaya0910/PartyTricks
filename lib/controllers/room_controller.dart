import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/rooms/room_providers.dart';
import 'package:party_tricks/services/rooms/room_service.dart';

/// Crea salas y entra a ellas. El estado es true mientras espera respuesta,
/// para mostrar que está cargando.
class RoomController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<Room> create(RoomSettings settings) {
    return _run(
      (service, me) => service.createRoom(
        uid: me.uid,
        username: me.username,
        settings: settings,
      ),
    );
  }

  Future<Room> joinByCode(String code) {
    return _run(
      (service, me) =>
          service.joinByCode(uid: me.uid, username: me.username, code: code),
    );
  }

  /// Devuelve null si no hay salas públicas con cupo.
  Future<Room?> joinRandom() {
    return _run(
      (service, me) =>
          service.joinRandomPublic(uid: me.uid, username: me.username),
    );
  }

  Future<void> leave(String roomId) async {
    final me = await ref.read(roomIdentityProvider.future);
    await ref.read(roomServiceProvider).leave(roomId: roomId, uid: me.uid);
  }

  Future<T> _run<T>(
    Future<T> Function(RoomService service, RoomIdentity me) action,
  ) async {
    state = true;
    try {
      final me = await ref.read(roomIdentityProvider.future);
      return await action(ref.read(roomServiceProvider), me);
    } finally {
      state = false;
    }
  }
}

final roomControllerProvider = NotifierProvider<RoomController, bool>(
  RoomController.new,
);
