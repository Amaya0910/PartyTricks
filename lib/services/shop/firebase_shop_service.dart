import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/chest.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/models/shop_cosmetic.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/services/shop/chest_roller.dart';
import 'package:party_tricks/services/shop/cosmetic_picker.dart';
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
    this._picker = const CosmeticPicker(),
  ]);

  final FirebaseFirestore _firestore;
  final RandomSource _random;
  final ChestRoller _roller;
  final CosmeticPicker _picker;

  @override
  Future<ChestPrize> buyChest({
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

        var prize = ChestPrize(_roller.roll(chest.odds, _random));
        final ownedEyes = _numbers(data['ownedEyes']);
        final ownedMouths = _numbers(data['ownedMouths']);
        final ownedShirts = _numbers(data['ownedShirts']);
        final ownedAccessories = _numbers(data['ownedAccessories']);
        if (prize.outcome == ChestOutcome.cosmetic) {
          // El cosmético es uno que todavía no tiene, según su rareza. Si ya
          // los tiene todos, el premio se cambia por monedas.
          prize =
              _picker.pick(
                ownedEyes: ownedEyes.toSet(),
                ownedMouths: ownedMouths.toSet(),
                ownedShirts: ownedShirts.toSet(),
                ownedAccessories: ownedAccessories.toSet(),
                random: _random,
              ) ??
              const ChestPrize(ChestOutcome.coins);
        }
        final outcome = prize.outcome;
        transaction.update(ref, {
          'diamonds': diamonds - chest.price,
          if (outcome == ChestOutcome.coins)
            'coins': _int(data['coins']) + chestCoinPrize,
          if (outcome == ChestOutcome.dice)
            'extraDice': _int(data['extraDice']) + 1,
          if (prize.eyes != null)
            'ownedEyes': [...ownedEyes, prize.eyes!.number],
          if (prize.mouth != null)
            'ownedMouths': [...ownedMouths, prize.mouth!.number],
          if (prize.shirt != null)
            'ownedShirts': [...ownedShirts, prize.shirt!.id],
          if (prize.accessory != null)
            'ownedAccessories': [...ownedAccessories, prize.accessory!.id],
        });
        transaction.set(
          FirestoreStatsDocument.ref(_firestore, uid),
          FirestoreStatsDocument.chestIncrements(chest, outcome),
          SetOptions(merge: true),
        );
        return prize;
      });
    } on FirebaseException catch (e) {
      throw ShopException(_messageFor(e));
    }
  }

  @override
  Future<void> buyEyes({required String uid, required EyeStyle eyes}) {
    if (eyes.isFree) throw const ShopException('Estos ojos ya son tuyos.');
    return _buyCosmetic(
      uid: uid,
      field: 'ownedEyes',
      cosmetic: eyes,
      alreadyOwned: 'Ya tienes estos ojos.',
    );
  }

  @override
  Future<void> buyMouth({required String uid, required MouthStyle mouth}) {
    if (mouth.isFree) throw const ShopException('Esta boca ya es tuya.');
    return _buyCosmetic(
      uid: uid,
      field: 'ownedMouths',
      cosmetic: mouth,
      alreadyOwned: 'Ya tienes esta boca.',
    );
  }

  @override
  Future<void> buyShirt({required String uid, required ShirtStyle shirt}) {
    if (shirt.isFree) throw const ShopException('Esta camisa ya es tuya.');
    return _buyCosmetic(
      uid: uid,
      field: 'ownedShirts',
      cosmetic: shirt,
      alreadyOwned: 'Ya tienes esta camisa.',
    );
  }

  @override
  Future<void> buyAccessory({
    required String uid,
    required AccessoryStyle accessory,
  }) {
    return _buyCosmetic(
      uid: uid,
      field: 'ownedAccessories',
      cosmetic: accessory,
      alreadyOwned: 'Ya tienes este accesorio.',
    );
  }

  /// Cobra las monedas de [cosmetic] y lo agrega a la lista [field] del
  /// perfil. Leer y cobrar van en una transacción: no se cobra dos veces ni
  /// se compra con monedas que ya se gastaron.
  Future<void> _buyCosmetic({
    required String uid,
    required String field,
    required ShopCosmetic cosmetic,
    required String alreadyOwned,
  }) async {
    final ref = _firestore.collection('users').doc(uid);
    try {
      await _firestore.runTransaction((transaction) async {
        final data = (await transaction.get(ref)).data();
        if (data == null) {
          throw const ShopException('No se encontró tu perfil.');
        }
        final owned = _numbers(data[field]);
        if (owned.contains(cosmetic.id)) throw ShopException(alreadyOwned);
        final coins = _int(data['coins']);
        if (coins < cosmetic.price) {
          throw const ShopException('No tienes suficientes monedas.');
        }
        transaction.update(ref, {
          'coins': coins - cosmetic.price,
          field: [...owned, cosmetic.id],
        });
      });
    } on FirebaseException catch (e) {
      throw ShopException(_messageFor(e));
    }
  }

  List<int> _numbers(Object? value) => [
    for (final item in value as List? ?? const [])
      if (item is num) item.toInt(),
  ];

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
