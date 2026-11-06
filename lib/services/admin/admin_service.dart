import 'package:party_tricks/models/admin/app_overview.dart';

/// Error del panel de administración, con un mensaje para mostrar.
class AdminException implements Exception {
  const AdminException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lo que usa el panel de administración. La versión real usa Cloud
/// Firestore; en las pruebas se puede cambiar por una falsa.
///
/// Quién es administrador lo decide el documento `admins/{uid}`, que solo
/// se crea a mano desde la consola de Firebase (decisiones.md, D-27).
abstract class AdminService {
  /// Si [uid] es administrador, en vivo.
  Stream<bool> watchIsAdmin(String uid);

  /// Los números de toda la app. Lanza [AdminException] si no se pueden
  /// leer (por ejemplo, si las reglas no están publicadas).
  Future<AppOverview> loadOverview();

  /// Suma (o resta, con números negativos) monedas, diamantes y dados
  /// extra a la cuenta de [uid]. Nunca deja nada por debajo de 0.
  Future<void> adjustWallet({
    required String uid,
    int coins = 0,
    int diamonds = 0,
    int extraDice = 0,
  });

  /// Deja en 0 las monedas, los diamantes y los dados extra de [uid].
  Future<void> resetWallet(String uid);
}
