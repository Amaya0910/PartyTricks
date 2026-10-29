import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/match_summary.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/shop_stats.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/models/stats/time_stats.dart';

/// Dónde viven las estadísticas en Firestore y cómo se suman sin leerlas.
///
/// Es el único lugar que conoce la ruta `stats/{uid}`. Lo usan
/// `FirebaseStatsService` y la tienda, que suma sus datos en la misma
/// transacción de la compra.
///
/// Los mapas de incrementos se guardan con `set(..., SetOptions(merge: true))`:
/// así se crean los campos que falten y no se borra nada más.
class FirestoreStatsDocument {
  const FirestoreStatsDocument._();

  static const collection = 'stats';

  static DocumentReference<Map<String, dynamic>> ref(
    FirebaseFirestore firestore,
    String uid,
  ) {
    return firestore.collection(collection).doc(uid);
  }

  /// Marca de una partida ya sumada: `stats/{uid}/matches/{matchId}`.
  static DocumentReference<Map<String, dynamic>> matchMarker(
    FirebaseFirestore firestore,
    String uid,
    String matchId,
  ) {
    return ref(firestore, uid).collection('matches').doc(matchId);
  }

  /// Perfil del jugador (`users/{uid}`), donde está su XP y lo de su cuenta.
  static DocumentReference<Map<String, dynamic>> profile(
    FirebaseFirestore firestore,
    String uid,
  ) {
    return firestore.collection('users').doc(uid);
  }

  /// Lo que la partida le deja a la cuenta: la XP y lo que sobró de monedas
  /// y diamantes (diseno_juego.md, sección 7).
  static Map<String, dynamic> matchRewards(MatchSummary match) => {
    'experience': FieldValue.increment(match.experience),
    'coins': FieldValue.increment(match.coins),
    'diamonds': FieldValue.increment(match.diamonds),
  };

  /// Lo que se guarda en la marca de la partida: sirve de historial.
  static Map<String, dynamic> matchMarkerData(MatchSummary match) => {
    'won': match.won,
    'place': match.place,
    'experience': match.experience,
    'coins': match.coins,
    'diamonds': match.diamonds,
    'recordedAt': FieldValue.serverTimestamp(),
  };

  static Map<String, dynamic> appTimeIncrement(Duration time) => {
    PlayerStats.timeKey: {
      TimeStats.secondsInAppKey: FieldValue.increment(time.inSeconds),
    },
  };

  static Map<String, dynamic> socialIncrement(SocialCounter counter) => {
    PlayerStats.socialKey: {counter.key: FieldValue.increment(1)},
  };

  static Map<String, dynamic> chestIncrements(
    ChestType chest,
    ChestOutcome outcome,
  ) => {
    PlayerStats.shopKey: {
      ShopStats.chestsOpenedKey: {chest.name: FieldValue.increment(1)},
      ShopStats.diamondsSpentKey: FieldValue.increment(chest.price),
      ShopStats.prizeKey(outcome): FieldValue.increment(1),
      if (outcome == ChestOutcome.coins)
        ShopStats.coinsFromChestsKey: FieldValue.increment(chestCoinPrize),
    },
  };
}
