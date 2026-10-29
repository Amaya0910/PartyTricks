import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';
import 'package:party_tricks/services/results/match_results_document.dart';
import 'package:party_tricks/services/results/results_service.dart';

/// Resultados en Cloud Firestore: `matchResults/{roomId}`. Se crea una sola
/// vez y no se cambia (las reglas no dejan editarlo ni borrarlo).
class FirebaseResultsService implements ResultsService {
  FirebaseResultsService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveMatch({
    required String roomId,
    required String hostUid,
    required bool isPublic,
    required MatchResults results,
  }) {
    final ref = _firestore
        .collection(MatchResultsDocument.collection)
        .doc(roomId);
    // Leer y crear en la misma transacción: si la pantalla se reconstruye y
    // se llama dos veces, se guarda una sola.
    return _firestore.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) return;
      transaction.set(ref, {
        ...MatchResultsDocument.toMap(
          roomId: roomId,
          hostUid: hostUid,
          isPublic: isPublic,
          results: results,
        ),
        'finishedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
