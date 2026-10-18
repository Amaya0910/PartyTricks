/// En qué momento está la sala.
enum RoomStatus { waiting, playing, closed }

/// Qué debe pasar con una sala que está esperando jugadores.
enum LobbyDecision { keepWaiting, start, close }

/// Lo que elige el creador al armar la sala (diseno_juego.md, sección 4.2).
class RoomSettings {
  RoomSettings({
    required this.isPublic,
    this.maxPlayers = 6,
    this.rounds = 10,
  }) {
    if (maxPlayers < Room.minPlayers || maxPlayers > Room.maxAllowedPlayers) {
      throw ArgumentError('La sala debe ser de 2 a 6 jugadores');
    }
    if (rounds < Room.minRounds || rounds > Room.maxRounds) {
      throw ArgumentError('Las rondas deben ser de 5 a 25');
    }
  }

  final bool isPublic;
  final int maxPlayers;
  final int rounds;
}

/// Un jugador dentro de la sala.
class RoomPlayer {
  const RoomPlayer({
    required this.uid,
    required this.username,
    required this.joinedAt,
    this.connected = true,
  });

  factory RoomPlayer.fromMap(String uid, Map<Object?, Object?> data) {
    return RoomPlayer(
      uid: uid,
      username: data['username'] as String,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(data['joinedAt'] as int),
      connected: data['connected'] as bool? ?? true,
    );
  }

  final String uid;
  final String username;
  final DateTime joinedAt;
  final bool connected;

  Map<String, Object?> toMap() => {
    'username': username,
    'joinedAt': joinedAt.millisecondsSinceEpoch,
    'connected': connected,
  };
}

/// Sala de juego guardada en Realtime Database en `rooms/{id}`.
class Room {
  const Room({
    required this.id,
    required this.code,
    required this.isPublic,
    required this.hostUid,
    required this.maxPlayers,
    required this.rounds,
    required this.status,
    required this.lobbyEndsAt,
    this.players = const {},
  });

  /// Lee `rooms/{id}`, que tiene `meta` y `players`.
  factory Room.fromMap(String id, Map<Object?, Object?> data) {
    final meta = data['meta'] as Map<Object?, Object?>;
    final players = data['players'] as Map<Object?, Object?>? ?? {};
    return Room(
      id: id,
      code: meta['code'] as String,
      isPublic: meta['isPublic'] as bool,
      hostUid: meta['hostUid'] as String,
      maxPlayers: meta['maxPlayers'] as int,
      rounds: meta['rounds'] as int,
      status: RoomStatus.values.byName(meta['status'] as String),
      lobbyEndsAt: DateTime.fromMillisecondsSinceEpoch(
        meta['lobbyEndsAt'] as int,
      ),
      players: {
        for (final entry in players.entries)
          entry.key as String: RoomPlayer.fromMap(
            entry.key as String,
            entry.value as Map<Object?, Object?>,
          ),
      },
    );
  }

  static const minPlayers = 2;
  static const maxAllowedPlayers = 6;
  static const minRounds = 5;
  static const maxRounds = 25;
  static const lobbyDuration = Duration(seconds: 90);

  final String id;
  final String code;
  final bool isPublic;
  final String hostUid;
  final int maxPlayers;
  final int rounds;
  final RoomStatus status;

  /// Hora en que se acaba la espera de 1:30.
  final DateTime lobbyEndsAt;

  /// Jugadores por uid.
  final Map<String, RoomPlayer> players;

  bool get isFull => players.length >= maxPlayers;

  /// Arranca si se llena; si no, al acabar el tiempo arranca con 2 o más
  /// jugadores y se cierra con menos (diseno_juego.md, sección 4.3).
  LobbyDecision decide(DateTime now) {
    if (isFull) return LobbyDecision.start;
    if (now.isBefore(lobbyEndsAt)) return LobbyDecision.keepWaiting;
    return players.length >= minPlayers
        ? LobbyDecision.start
        : LobbyDecision.close;
  }

  /// Lo que va en `rooms/{id}/meta`.
  Map<String, Object?> metaToMap() => {
    'code': code,
    'isPublic': isPublic,
    'hostUid': hostUid,
    'maxPlayers': maxPlayers,
    'rounds': rounds,
    'status': status.name,
    'lobbyEndsAt': lobbyEndsAt.millisecondsSinceEpoch,
  };
}
