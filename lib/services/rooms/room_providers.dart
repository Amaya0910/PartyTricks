import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/rooms/disconnection_policy.dart';
import 'package:party_tricks/services/rooms/firebase_room_service.dart';
import 'package:party_tricks/services/rooms/presence_service.dart';
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

/// Quién es el jugador en las salas: su uid y su nombre de usuario real
/// (para que sus amigos lo reconozcan). Si aún no hay sesión, entra como
/// usuario anónimo con un nombre de prueba.
final roomIdentityProvider = FutureProvider<RoomIdentity>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile != null) {
    return RoomIdentity(uid: profile.uid, username: profile.username);
  }
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
  return RoomIdentity(
    uid: user.uid,
    username: 'Jugador ${user.uid.substring(0, 4)}',
  );
});

/// La sala en vivo, por id.
final roomProvider = StreamProvider.family<Room?, String>(
  (ref, roomId) => ref.watch(roomServiceProvider).watchRoom(roomId),
);

final presenceServiceProvider = Provider<PresenceService>(
  (ref) => FirebasePresenceService(FirebaseDatabase.instance),
);

/// Cuánto se espera a los desconectados. Se puede cambiar aquí (o en las
/// pruebas) sin tocar la lógica.
final disconnectionPolicyProvider = Provider<DisconnectionPolicy>(
  (ref) => const DisconnectionPolicy(),
);

/// La sala de la partida en curso del jugador, si tiene una. Sirve para
/// volver a ella si cerró la app.
final activeGameProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(userProfileProvider.select((p) => p.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(roomServiceProvider).watchActiveGame(uid);
});
