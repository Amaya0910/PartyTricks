import 'package:party_tricks/services/results/match_results_document.dart';

/// Números de toda la app para el panel de administración. Se calculan en
/// Firestore con consultas de conteo y suma, sin descargar los documentos.
class AppOverview {
  const AppOverview({
    this.users = 0,
    this.totalExperience = 0,
    this.totalCoins = 0,
    this.totalDiamonds = 0,
    this.matches = 0,
    this.publicMatches = 0,
    this.minigamesWon = 0,
    this.secondsInApp = 0,
    this.diamondsSpent = 0,
    this.recentMatches = const [],
  });

  /// Cuentas registradas (`users`).
  final int users;

  /// Lo que hay guardado entre todas las cuentas.
  final int totalExperience;
  final int totalCoins;
  final int totalDiamonds;

  /// Partidas terminadas (`matchResults`) y cuántas fueron públicas.
  final int matches;
  final int publicMatches;

  /// Sumas de las estadísticas de todos (`stats`).
  final int minigamesWon;
  final int secondsInApp;
  final int diamondsSpent;

  /// Las últimas partidas terminadas, de la más nueva a la más vieja.
  final List<MatchRecord> recentMatches;

  /// Partidas terminadas por cuenta, con un decimal.
  double get matchesPerUser => users == 0 ? 0 : matches / users;
}
