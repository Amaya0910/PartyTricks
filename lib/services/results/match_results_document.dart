import 'package:party_tricks/services/game_engine/award_calculator.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';

/// Un jugador en el registro de una partida terminada.
class MatchRecordPlayer {
  const MatchRecordPlayer({
    required this.uid,
    required this.username,
    required this.place,
    required this.coins,
    required this.diamonds,
    required this.experience,
    this.awards = const [],
  });

  final String uid;
  final String username;
  final int place;
  final int coins;
  final int diamonds;
  final int experience;
  final List<FinalAward> awards;
}

/// Lo que queda guardado de una partida, leído de vuelta. Sirve para los
/// rankings globales y el historial.
class MatchRecord {
  const MatchRecord({
    required this.roomId,
    required this.hostUid,
    required this.isPublic,
    required this.rounds,
    required this.winnerIds,
    required this.players,
  });

  final String roomId;
  final String hostUid;
  final bool isPublic;
  final int rounds;
  final List<String> winnerIds;

  /// Del primero al último.
  final List<MatchRecordPlayer> players;
}

/// Cómo se guarda una partida terminada en `matchResults/{roomId}`.
///
/// Es el único lugar que conoce el formato. No depende de Firebase para
/// poder probarlo solo; la fecha la pone el servicio.
class MatchResultsDocument {
  const MatchResultsDocument._();

  static const collection = 'matchResults';

  /// Sube si cambia el formato, para que los rankings sepan leer los viejos.
  static const schemaVersion = 1;

  static Map<String, dynamic> toMap({
    required String roomId,
    required String hostUid,
    required bool isPublic,
    required MatchResults results,
  }) {
    return {
      'schemaVersion': schemaVersion,
      'roomId': roomId,
      'hostUid': hostUid,
      'isPublic': isPublic,
      'rounds': results.rounds,
      'winnerIds': results.winnerIds,
      // Lista aparte para buscar "partidas de este jugador" (array-contains).
      'playerIds': [for (final r in results.ranking) r.id],
      'players': [
        for (final r in results.ranking)
          {
            'uid': r.id,
            'username': r.username,
            'place': r.place,
            'coins': r.coins,
            'diamonds': r.diamonds,
            'experience': r.experience,
            'awards': [for (final award in r.awards) award.name],
          },
      ],
    };
  }

  static MatchRecord fromMap(Map<String, dynamic> data) {
    int read(Object? value) => (value as num?)?.toInt() ?? 0;
    return MatchRecord(
      roomId: data['roomId'] as String? ?? '',
      hostUid: data['hostUid'] as String? ?? '',
      isPublic: data['isPublic'] as bool? ?? false,
      rounds: read(data['rounds']),
      winnerIds: [
        for (final id in data['winnerIds'] as List? ?? const []) id as String,
      ],
      players: [
        for (final raw in data['players'] as List? ?? const [])
          if (raw case final Map<Object?, Object?> p)
            MatchRecordPlayer(
              uid: p['uid'] as String? ?? '',
              username: p['username'] as String? ?? '',
              place: read(p['place']),
              coins: read(p['coins']),
              diamonds: read(p['diamonds']),
              experience: read(p['experience']),
              awards: [
                for (final name in p['awards'] as List? ?? const [])
                  for (final award in FinalAward.values)
                    if (award.name == name) award,
              ],
            ),
      ],
    );
  }
}
