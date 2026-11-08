import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/models/map/map_id.dart';

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
    this.mapId = defaultMapId,
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

  /// El mapa que se va a jugar. Por ahora siempre el de por defecto.
  final String mapId;
}

/// Un jugador dentro de la sala.
class RoomPlayer {
  const RoomPlayer({
    required this.uid,
    required this.username,
    required this.joinedAt,
    this.connected = true,
    this.lastSeen,
    this.photoUrl,
    this.protocol = AppProtocol.current,
  });

  factory RoomPlayer.fromMap(String uid, Map<Object?, Object?> data) {
    return RoomPlayer(
      uid: uid,
      username: data['username'] as String,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(data['joinedAt'] as int),
      connected: data['connected'] as bool? ?? true,
      lastSeen: _time(data['lastSeen']),
      photoUrl: data['photoUrl'] as String?,
      // Los que entraron con la 1.0.0 no lo publican.
      protocol: (data['protocol'] as num?)?.toInt() ?? AppProtocol.legacy,
    );
  }

  final String uid;
  final String username;
  final DateTime joinedAt;
  final bool connected;

  /// Última vez que la presencia lo vio (hora del servidor). Null en las
  /// salas guardadas antes de `feature/disconnections`.
  final DateTime? lastSeen;

  /// Foto de perfil (opcional). Si es null se muestra un ícono.
  final String? photoUrl;

  /// El protocolo de la app con la que entró ([AppProtocol]). Las reglas no
  /// lo dejan entrar si es menor que el `requiredProtocol` de la sala.
  final int protocol;

  Map<String, Object?> toMap() => {
    'username': username,
    'joinedAt': joinedAt.millisecondsSinceEpoch,
    'connected': connected,
    if (lastSeen != null) 'lastSeen': lastSeen!.millisecondsSinceEpoch,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'protocol': protocol,
  };
}

DateTime? _time(Object? value) =>
    value is num ? DateTime.fromMillisecondsSinceEpoch(value.toInt()) : null;

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
    this.mapId = defaultMapId,
    this.requiredProtocol = AppProtocol.legacy,
    this.lastActiveAt,
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
      // Las salas de antes de los varios mapas no lo tienen.
      mapId: meta['mapId'] as String? ?? defaultMapId,
      requiredProtocol:
          (meta['requiredProtocol'] as num?)?.toInt() ?? AppProtocol.legacy,
      lastActiveAt: _time(meta['lastActiveAt']),
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

  /// El mapa que se va a jugar. Al arrancar se copia a la partida
  /// (`GameState.mapId`), que es la que manda desde ahí.
  final String mapId;

  /// El protocolo mínimo para entrar: el mayor de lo que usa la partida
  /// (mapa y, más adelante, minijuegos, ítems...). Lo calcula quien crea la
  /// sala y no cambia. Ver `AppProtocol` y `docs/protocolo.md`.
  final int requiredProtocol;

  /// Última vez que el anfitrión dio señales (lo renueva mientras juega).
  /// Sirve para saber si la sala quedó abandonada.
  final DateTime? lastActiveAt;

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
    'mapId': mapId,
    'requiredProtocol': requiredProtocol,
    if (lastActiveAt != null)
      'lastActiveAt': lastActiveAt!.millisecondsSinceEpoch,
  };
}
