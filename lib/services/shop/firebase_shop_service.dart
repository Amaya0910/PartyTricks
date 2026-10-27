import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/services/shop/chest_roller.dart';
import 'package:party_tricks/services/shop/shop_service.dart';
import 'package:party_tricks/services/stats/firestore_stats_document.dart';

/// Compras sobre el perfil `users/{uid}` de Cloud Firestore.
///
/// Cobrar, dar el premio y sumarlo a las estadísticas (`stats/{uid}`) van
/// en una sola transacción, así nunca se cobra sin premio ni se gasta dos
/// veces el mismo diamante.
class FirebaseShopService implements ShopService {
  FirebaseShopService(
    this._firestore,
    this._random, [
    this._roller = const ChestRoller(),
  ]);

  final FirebaseFirestore _firestore;
  final RandomSource _random;
  final ChestRoller _roller;

  @override
  Future<ChestOutcome> buyChest({
    required String uid,
    required ChestType chest,
  }) async {
    final ref = _firestore.collection('users').doc(uid);
    try {
      return await _firestore.runTransaction((transaction) async {
        final data = (await transaction.get(ref)).data();
        if (data == null) {
          throw const ShopException('No se encontró tu perfil.');
        }
        final diamonds = _int(data['diamonds']);
        if (diamonds < chest.price) {
          throw const ShopException('No tienes suficientes diamantes.');
        }

        final outcome = _roller.roll(chest.odds, _random);
        // TODO(feature/player-profile): guardar el cosmético cuando exista
        // el catálogo; por ahora solo se guardan las monedas y el dado extra.
        transaction.update(ref, {
          'diamonds': diamonds - chest.price,
          if (outcome == ChestOutcome.coins)
            'coins': _int(data['coins']) + chestCoinPrize,
          if (outcome == ChestOutcome.dice)
            'extraDice': _int(data['extraDice']) + 1,
        });
        transaction.set(
          FirestoreStatsDocument.ref(_firestore, uid),
          FirestoreStatsDocument.chestIncrements(chest, outcome),
          SetOptions(merge: true),
        );
        return outcome;
      });
    } on FirebaseException catch (e) {
      throw ShopException(_messageFor(e));
    }
  }

  int _int(Object? value) => (value as num?)?.toInt() ?? 0;

  String _messageFor(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Sin permiso para comprar. Revisa las reglas de Firestore.';
      case 'unavailable':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'No se pudo completar la compra. Intenta de nuevo.';
    }
  }
}