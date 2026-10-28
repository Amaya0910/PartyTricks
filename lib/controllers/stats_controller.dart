import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/social/social_providers.dart';
import 'package:party_tricks/services/stats/match_summary_builder.dart';
import 'package:party_tricks/services/stats/match_time_tracker.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

/// Guarda en las estadísticas lo que pasa en la app: partidas terminadas,
/// tiempo de uso, días activos (racha) y acciones sociales.
///
/// Las estadísticas no son críticas: si algo falla, no se interrumpe al
/// jugador; solo se anota en la consola.
class StatsController {
  StatsController(this._ref, {MatchSummaryBuilder? summaries})
    : _summaries = summaries ?? const MatchSummaryBuilder();

  final Ref _ref;
  final MatchSummaryBuilder _summaries;

  /// Menos de esto no vale la pena guardarlo.
  static const minAppTime = Duration(seconds: 1);

  String? get _uid => _ref.read(userProfileProvider).value?.uid;

  /// Suma la partida [game] (ya terminada) a las estadísticas del jugador.
  /// Devuelve false si no se pudo (sin sesión, partida sin terminar o error).
  Future<bool> recordFinishedMatch({
    required String roomId,
    required GameState game,
    required MatchTimeTracker tracker,
    bool isHost = false,
    bool isPublic = false,
  }) async {
    final uid = _uid;
    if (uid == null) return false;
    final friends = _ref.read(friendUidsProvider);
    final summary = _summaries.build(
      matchId: roomId,
      game: game,
      playerId: uid,
      isHost: isHost,
      isPublic: isPublic,
      playedWithFriend: game.players.keys.any(friends.contains),
      playingTime: tracker.playingTime,
      minigameTime: tracker.minigameTime,
    );
    if (summary == null) return false;
    return _safely(
      () => _ref.read(statsServiceProvider).recordMatch(uid, summary),
    );
  }

  /// Suma [time] al tiempo en la app.
  Future<bool> addAppTime(Duration time) async {
    final uid = _uid;
    if (uid == null || time < minAppTime) return false;
    return _safely(() => _ref.read(statsServiceProvider).addAppTime(uid, time));
  }

  /// Marca hoy como día activo (para la racha).
  Future<bool> registerActivity() async {
    final uid = _uid;
    if (uid == null) return false;
    final now = _ref.read(clockProvider)();
    return _safely(
      () => _ref.read(statsServiceProvider).registerActivity(uid, now),
    );
  }

  /// Suma 1 a un contador social. Lo usará `feature/friends-chat`.
  Future<bool> recordSocial(SocialCounter counter) async {
    final uid = _uid;
    if (uid == null) return false;
    return _safely(
      () => _ref.read(statsServiceProvider).recordSocial(uid, counter),
    );
  }

  Future<bool> _safely(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (error) {
      debugPrint('No se pudieron guardar las estadísticas: $error');
      return false;
    }
  }
}

final statsControllerProvider = Provider<StatsController>(
  StatsController.new,
);
