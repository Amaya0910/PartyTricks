import 'package:party_tricks/services/game_engine/match_results.dart';

/// Registro público de las partidas terminadas, para rankings globales e
/// historial. La versión real usa Cloud Firestore.
abstract class ResultsService {
  /// Solo el anfitrión: guarda el resultado de la partida [roomId]. Si ya
  /// estaba guardado, no hace nada.
  Future<void> saveMatch({
    required String roomId,
    required String hostUid,
    required bool isPublic,
    required MatchResults results,
  });
}
