import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/rooms/firebase_room_service.dart';
import 'package:party_tricks/services/rooms/room_service.dart';

/// Quién es el jugador para las salas.
class RoomIdentity {
  const RoomIdentity({required this.uid, required this.username});

  final String uid;
  final String username;
}

final roomServiceProvider = Provider<RoomService>(
  (ref) => FirebaseRoomService(FirebaseDatabase.instance),
);

/// Provisional hasta que exista feature/auth: entra como usuario anónimo y
/// usa un nombre de prueba.
final roomIdentityProvider = FutureProvider<RoomIdentity>((ref) async {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
  return RoomIdentity(
    uid: user.uid,
    username: user.displayName ?? 'Jugador ${user.uid.substring(0, 4)}',
  );
});

/// La sala en vivo, por id.
final roomProvider = StreamProvider.family<Room?, String>(
  (ref, roomId) => ref.watch(roomServiceProvider).watchRoom(roomId),
);
