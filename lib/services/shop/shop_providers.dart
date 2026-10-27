import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/services/shop/firebase_shop_service.dart';
import 'package:party_tricks/services/shop/shop_service.dart';

final shopServiceProvider = Provider<ShopService>(
  (ref) => FirebaseShopService(FirebaseFirestore.instance, DartRandomSource()),
);