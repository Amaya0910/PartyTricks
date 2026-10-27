import 'package:firebase_database/firebase_database.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/rooms/room_code_generator.dart';
import 'package:party_tricks/services/rooms/room_service.dart';

/// Salas en Realtime Database.
///
/// - `rooms/{id}/meta` y `rooms/{id}/players/{uid}`: la sala.
/// - `roomCodes/{code}`: id de la sala con ese código.
/// - `publicLobby/{id}`: salas públicas que esperan jugadores.
class FirebaseRoomService implements RoomService {
  FirebaseRoomService(this._db, [RoomCodeGenerator? codes])
    : _codes = codes ?? RoomCodeGenerator();

  final FirebaseDatabase _db;
  final RoomCodeGenerator _codes;

  DatabaseReference _room(String id) => _db.ref('rooms/$id');

  @override
  Future<Room> createRoom({
    required String uid,
    required String username,
    required RoomSettings settings,
  }) async {
    final id = _db.ref('rooms').push().key!;
    final code = await _reserveCode(id);
    final now = DateTime.now();
    final room = Room(
      id: id,
      code: code,
      isPublic: settings.isPublic,
      hostUid: uid,
      maxPlayers: settings.maxPlayers,
      rounds: settings.rounds,
      status: RoomStatus.waiting,
      lobbyEndsAt: now.add(Room.lobbyDuration),
      players: {uid: RoomPlayer(uid: uid, username: username, joinedAt: now)},
    );
    await _db.ref().update({
      'rooms/$id/meta': room.metaToMap(),
      'rooms/$id/players/$uid': room.players[uid]!.toMap(),
      if (settings.isPublic) 'publicLobby/$id': true,
    });
    return room;
  }

  @override
  Future<Room> joinByCode({
    required String uid,
    required String username,
    required String code,
  }) async {
    final normalized = RoomCodeGenerator.normalize(code);
    if (!RoomCodeGenerator.isValid(normalized)) {
      throw const RoomException('El código no es válido');
    }
    final snapshot = await _db.ref('roomCodes/$normalized').get();
    final id = snapshot.value as String?;
    if (id == null) {
      throw const RoomException('No existe una sala con ese código');
    }
    return _join(id, uid, username);
  }

  @override
  Future<Room?> joinRandomPublic({
    required String uid,
    required String username,
  }) async {
    final snapshot = await _db.ref('publicLobby').limitToFirst(20).get();
    for (final child in snapshot.children) {
      try {
        return await _join(child.key!, uid, username);
      } on RoomException {
        // Esa sala se llenó o arrancó; se prueba con la siguiente.
      }
    }
    return null;
  }

  @override
  Future<void> leave({required String roomId, required String uid}) {
    return _room(roomId).child('players/$uid').remove();
  }

  @override
  Future<void> setStatus(Room room, RoomStatus status) {
    return _db.ref().update({
      'rooms/${room.id}/meta/status': status.name,
      if (status != RoomStatus.waiting) 'publicLobby/${room.id}': null,
      if (status == RoomStatus.closed) 'roomCodes/${room.code}': null,
    });
  }

  @override
  Stream<Room?> watchRoom(String roomId) {
    return _room(roomId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      return Room.fromMap(roomId, value as Map<Object?, Object?>);
    });
  }

  /// Busca un código libre y lo aparta para la sala [roomId].
  Future<String> _reserveCode(String roomId) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _codes.generate();
      final result = await _db
          .ref('roomCodes/$code')
          .runTransaction(
            (current) => current == null
                ? Transaction.success(roomId)
                : Transaction.abort(),
          );
      if (result.committed) return code;
    }
    throw const RoomException('No se pudo crear la sala, intenta otra vez');
  }

  /// Agrega al jugador si la sala espera jugadores y tiene cupo. La
  /// transacción evita que dos entren al último puesto al mismo tiempo.
  Future<Room> _join(String id, String uid, String username) async {
    final snapshot = await _room(id).get();
    if (snapshot.value == null) {
      throw const RoomException('La sala ya no existe');
    }
    final room = Room.fromMap(id, snapshot.value as Map<Object?, Object?>);
    if (room.players.containsKey(uid)) return room;
    if (room.status != RoomStatus.waiting) {
      throw const RoomException('La partida ya empezó');
    }

    final player = RoomPlayer(
      uid: uid,
      username: username,
      joinedAt: DateTime.now(),
    );
    final result = await _room(id).child('players').runTransaction((current) {
      final players = Map<Object?, Object?>.of(
        current as Map<Object?, Object?>? ?? {},
      );
      if (players.length >= room.maxPlayers) return Transaction.abort();
      players[uid] = player.toMap();
      return Transaction.success(players);
    });
    if (!result.committed) throw const RoomException('La sala está llena');

    return Room.fromMap(id, {
      'meta': room.metaToMap(),
      'players': result.snapshot.value,
    });
  }
}
