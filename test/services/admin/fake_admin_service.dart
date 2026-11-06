import 'dart:async';

import 'package:party_tricks/models/admin/app_overview.dart';
import 'package:party_tricks/services/admin/admin_service.dart';

/// Panel de administración en memoria para las pruebas.
class FakeAdminService implements AdminService {
  FakeAdminService({this.admins = const {}, this.overview});

  /// Uids con documento en `admins`.
  final Set<String> admins;

  /// Lo que devuelve [loadOverview]; si es null, falla.
  AppOverview? overview;

  /// Monedas, diamantes y dados extra por uid.
  final Map<String, ({int coins, int diamonds, int extraDice})> wallets = {};

  ({int coins, int diamonds, int extraDice}) walletOf(String uid) =>
      wallets[uid] ?? (coins: 0, diamonds: 0, extraDice: 0);

  @override
  Stream<bool> watchIsAdmin(String uid) => Stream.value(admins.contains(uid));

  @override
  Future<AppOverview> loadOverview() async {
    final value = overview;
    if (value == null) throw const AdminException('Sin permiso.');
    return value;
  }

  @override
  Future<void> adjustWallet({
    required String uid,
    int coins = 0,
    int diamonds = 0,
    int extraDice = 0,
  }) async {
    final w = walletOf(uid);
    int floor(int value) => value < 0 ? 0 : value;
    wallets[uid] = (
      coins: floor(w.coins + coins),
      diamonds: floor(w.diamonds + diamonds),
      extraDice: floor(w.extraDice + extraDice),
    );
  }

  @override
  Future<void> resetWallet(String uid) async {
    wallets[uid] = (coins: 0, diamonds: 0, extraDice: 0);
  }
}
