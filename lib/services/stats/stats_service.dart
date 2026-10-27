import 'package:party_tricks/models/match_summary.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/social_stats.dart';

/// Estadísticas del jugador. La versión real usa Cloud Firestore; en las
/// pruebas se puede cambiar por una falsa.
///
/// Las compras de cofres no pasan por aquí: la tienda las suma en la misma
/// transacción de la compra.
abstract class StatsService {
  /// Las estadísticas en vivo. Si el jugador aún no tiene, emite
  /// [PlayerStats.empty].
  Stream<PlayerStats> watchStats(String uid);

  /// Suma una partida terminada. Si esa partida ya se había sumado
  /// (mismo [MatchSummary.matchId]), no hace nada.
  Future<void> recordMatch(String uid, MatchSummary match);

  /// Suma tiempo de uso de la app.
  Future<void> addAppTime(String uid, Duration time);

  /// Marca el día de [now] como activo y actualiza la racha.
  Future<void> registerActivity(String uid, DateTime now);

  /// Suma 1 a un contador social (invitación enviada, mensaje...).
  Future<void> recordSocial(String uid, SocialCounter counter);
}
