import 'package:party_tricks/models/room.dart';

/// Error al crear o entrar a una sala, con un mensaje para mostrar.
class RoomException implements Exception {
  const RoomException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Operaciones con las salas. La versión real usa Realtime Database; en las
/// pruebas se puede cambiar por una falsa.
abstract class RoomService {
  /// Crea la sala y mete al creador como primer jugador.
  Future<Room> createRoom({
    required String uid,
    required String username,
    required RoomSettings settings,
  });

  /// Entra a una sala con su código. Lanza [RoomException] si no existe,
  /// está llena o ya empezó.
  Future<Room> joinByCode({
    required String uid,
    required String username,
    required String code,
  });

  /// Entra a una sala pública con cupo. Devuelve null si no hay ninguna.
  Future<Room?> joinRandomPublic({
    required String uid,
    required String username,
  });

  /// Saca al jugador de la sala.
  Future<void> leave({required String roomId, required String uid});

  /// Cambia el estado. Solo lo hace el creador (arrancar o cerrar).
  Future<void> setStatus(Room room, RoomStatus status);

  /// La sala en vivo. Emite null si la borran.
  Stream<Room?> watchRoom(String roomId);
}
