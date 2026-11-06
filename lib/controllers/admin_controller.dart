import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/admin/admin_providers.dart';
import 'package:party_tricks/services/admin/admin_service.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';

/// Herramientas de economía del panel de administración. Solo cambian la
/// cuenta propia, para probar la tienda y los cofres.
class AdminController {
  AdminController(this._ref);

  final Ref _ref;

  String get _uid {
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) throw const AdminException('Inicia sesión primero.');
    if (_ref.read(isAdminProvider).value != true) {
      throw const AdminException('Esta cuenta no es administradora.');
    }
    return uid;
  }

  /// Lanza [AdminException] con el mensaje a mostrar.
  Future<void> adjustWallet({
    int coins = 0,
    int diamonds = 0,
    int extraDice = 0,
  }) {
    return _ref
        .read(adminServiceProvider)
        .adjustWallet(
          uid: _uid,
          coins: coins,
          diamonds: diamonds,
          extraDice: extraDice,
        );
  }

  /// Deja la cuenta propia en 0. Lanza [AdminException].
  Future<void> resetWallet() =>
      _ref.read(adminServiceProvider).resetWallet(_uid);
}

final adminControllerProvider = Provider<AdminController>(AdminController.new);
