import 'package:party_tricks/services/game_engine/match_results.dart';
import 'package:party_tricks/services/results/results_service.dart';

/// Registro de partidas en memoria para las pruebas. Como el real, guarda
/// cada sala una sola vez.
class FakeResultsService implements ResultsService {
  /// Si no es null, la próxima operación lanza este error.
  Object? nextError;

  final Map<String, ({String hostUid, bool isPublic, MatchResults results})>
  saved = {};

  @override
  Future<void> saveMatch({
    required String roomId,
    required String hostUid,
    required bool isPublic,
    required MatchResults results,
  }) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    saved.putIfAbsent(
      roomId,
      () => (hostUid: hostUid, isPublic: isPublic, results: results),
    );
  }
}
