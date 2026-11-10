import 'package:cloud_firestore/cloud_firestore.dart';

/// Reserva del nombre de usuario en `usernames/{nombre en minúsculas}`.
///
/// Solo guarda el uid: el correo no se publica (H-01). Las reservas viejas
/// que todavía tienen el correo solo las puede leer su dueño, así que si la
/// de otro no se puede leer, el nombre está tomado.
abstract final class UsernameReservation {
  /// Lo que se guarda en la reserva.
  static Map<String, Object> data(String uid) => {'uid': uid};

  /// Si el nombre de [ref] ya es de alguien.
  static Future<bool> isTaken(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return (await transaction.get(ref)).exists;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return true;
      rethrow;
    }
  }
}
