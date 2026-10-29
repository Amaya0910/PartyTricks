import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';
import 'package:party_tricks/services/results/results_providers.dart';

/// Guarda el resultado de la partida en el registro global. Lo hace solo el
/// anfitrión; las estadísticas y la XP de cada jugador las guarda cada uno
/// con `StatsController`.
///
/// Como las estadísticas, no es crítico: si falla, el jugador igual ve sus
/// resultados y solo se anota en la consola.
class ResultsController {
  ResultsController(this._ref, {MatchResultsBuilder? results})
    : _results = results ?? const MatchResultsBuilder();

  final Ref _ref;
  final MatchResultsBuilder _results;

  /// Devuelve false si la partida no terminó o no se pudo guardar.
  Future<bool> saveFinishedMatch({
    required String roomId,
    required String hostUid,
    required GameState game,
    bool isPublic = false,
  }) async {
    if (game.phase != GamePhase.finished) return false;
    try {
      await _ref
          .read(resultsServiceProvider)
          .saveMatch(
            roomId: roomId,
            hostUid: hostUid,
            isPublic: isPublic,
            results: _results.build(game),
          );
      return true;
    } catch (error) {
      debugPrint('No se pudo guardar el resultado de la partida: $error');
      return false;
    }
  }
}

final resultsControllerProvider = Provider<ResultsController>(
  ResultsController.new,
);
