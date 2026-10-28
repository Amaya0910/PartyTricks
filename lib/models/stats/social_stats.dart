import 'package:party_tricks/models/stats/stats_map.dart';

/// Contadores sociales que se suman uno a uno, sin leer antes.
enum SocialCounter {
  inviteSent('invitesSent'),
  inviteAccepted('invitesAccepted'),
  messageSent('messagesSent');

  const SocialCounter(this.key);

  /// Clave del campo en Firestore.
  final String key;
}

/// Un jugador con el que se ha compartido partida.
class PartnerStats {
  const PartnerStats({required this.username, this.matches = 0});

  /// Último nombre conocido (puede cambiar en Ajustes).
  final String username;
  final int matches;

  factory PartnerStats.fromMap(Map<String, dynamic> map) {
    return PartnerStats(
      username: map['username'] as String? ?? '',
      matches: StatsMap.readInt(map, 'matches'),
    );
  }

  Map<String, dynamic> toMap() => {'username': username, 'matches': matches};
}

/// Estadísticas sociales.
///
/// Los compañeros de partida ya se cuentan. Las invitaciones, los mensajes
/// y las partidas con amigos quedan listos para cuando llegue
/// `feature/friends-chat`.
class SocialStats {
  const SocialStats({
    this.invitesSent = 0,
    this.invitesAccepted = 0,
    this.messagesSent = 0,
    this.matchesWithFriends = 0,
    this.playedWith = const {},
  });

  final int invitesSent;
  final int invitesAccepted;
  final int messagesSent;
  final int matchesWithFriends;

  /// Compañeros de partida por uid.
  final Map<String, PartnerStats> playedWith;

  /// El jugador con el que más partidas ha compartido, o null si ninguno.
  /// En un empate gana el primero por uid, para que no cambie cada vez.
  PartnerStats? get favoritePartner {
    PartnerStats? best;
    final uids = playedWith.keys.toList()..sort();
    for (final uid in uids) {
      final partner = playedWith[uid]!;
      if (best == null || partner.matches > best.matches) best = partner;
    }
    return best;
  }

  factory SocialStats.fromMap(Map<String, dynamic> map) {
    final partners = StatsMap.readMap(map, 'playedWith');
    return SocialStats(
      invitesSent: StatsMap.readInt(map, SocialCounter.inviteSent.key),
      invitesAccepted: StatsMap.readInt(map, SocialCounter.inviteAccepted.key),
      messagesSent: StatsMap.readInt(map, SocialCounter.messageSent.key),
      matchesWithFriends: StatsMap.readInt(map, 'matchesWithFriends'),
      playedWith: {
        for (final uid in partners.keys)
          uid: PartnerStats.fromMap(StatsMap.readMap(partners, uid)),
      },
    );
  }

  Map<String, dynamic> toMap() => {
    SocialCounter.inviteSent.key: invitesSent,
    SocialCounter.inviteAccepted.key: invitesAccepted,
    SocialCounter.messageSent.key: messagesSent,
    'matchesWithFriends': matchesWithFriends,
    'playedWith': {
      for (final entry in playedWith.entries) entry.key: entry.value.toMap(),
    },
  };
}
