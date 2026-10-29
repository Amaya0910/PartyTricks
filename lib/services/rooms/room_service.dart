import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/rooms/disconnection_policy.dart';

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

  /// Saca al jugador de la sala. Si era el último, borra la sala.
  Future<void> leave({required String roomId, required String uid});

  /// Toma el lugar del anfitrión [expectedHost] si todavía lo es (si otro
  /// ya lo tomó, no hace nada). Devuelve true si [uid] quedó de anfitrión.
  Future<bool> claimHost({
    required String roomId,
    required String expectedHost,
    required String uid,
  });

  /// Solo el anfitrión: avisa que la sala sigue viva (`meta/lastActiveAt`).
  Future<void> touch(String roomId);

  /// Borra de la lista pública las salas que ya no existen y las que
  /// quedaron abandonadas. Devuelve cuántas quitó.
  Future<int> cleanAbandoned(DisconnectionPolicy policy, DateTime now);

  /// La partida en curso del jugador, para volver a ella si cierra la app.
  /// Con null se borra.
  Future<void> setActiveGame(String uid, String? roomId);

  Stream<String?> watchActiveGame(String uid);

  /// Cambia el estado. Solo lo hace el creador (arrancar o cerrar).
  Future<void> setStatus(Room room, RoomStatus status);

  /// La sala en vivo. Emite null si la borran.
  Stream<Room?> watchRoom(String roomId);
}
