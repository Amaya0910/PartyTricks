import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_tricks/models/chest.dart';
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
