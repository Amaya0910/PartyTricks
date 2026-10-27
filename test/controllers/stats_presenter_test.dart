import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/stats_presenter.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/board_stats.dart';
import 'package:party_tricks/models/stats/match_stats.dart';
import 'package:party_tricks/models/stats/shop_stats.dart';
import 'package:party_tricks/models/stats/social_stats.dart';
import 'package:party_tricks/models/stats/stats_section.dart';
import 'package:party_tricks/models/stats/time_stats.dart';
import 'package:party_tricks/services/stats/stats_format.dart';

void main() {
  const presenter = StatsPresenter();

  String valueOf(List<StatsSection> sections, String title, String label) {
    final section = sections.firstWhere((s) => s.title == title);
    return section.rows.firstWhere((r) => r.label == label).value;
  }

  test('las tres primeras tarjetas son las del mockup, en su orden', () {
    final titles = [
      for (final s in presenter.sections(PlayerStats.empty)) s.title,
    ];

    expect(titles.take(3), ['Partidas', 'Minijuegos', 'Tiempo']);
    expect(titles, [
      'Partidas',
      'Minijuegos',
      'Tiempo',
      'Podio',
      'Premios finales',
      'Detalle de partidas',
      'Tablero',
      'Minijuegos por tipo',
      'Tienda',
      'Social',
    ]);
  });

  test('los colores se repiten en orden: azul, azul oscuro y morado', () {
    final tones = [
      for (final s in presenter.sections(PlayerStats.empty)) s.tone,
    ];

    for (var i = 0; i < tones.length; i++) {
      expect(tones[i], StatsTone.values[i % StatsTone.values.length]);
    }
  });

  test('formatea los valores', () {
    const stats = PlayerStats(
      matches: MatchStats(won: 5, lost: 5, totalDiamonds: 25),
      board: BoardStats(diceRolled: 4, diceTotal: 14),
      shop: ShopStats(chestsOpened: {'basic': 2}),
      social: SocialStats(
        playedWith: {'u2': PartnerStats(username: 'Beto', matches: 3)},
      ),
      time: TimeStats(secondsInApp: 12000, currentStreak: 6),
    );

    final sections = presenter.sections(stats);

    expect(valueOf(sections, 'Partidas', 'Porcentaje de ganadas:'), '50%');
    expect(valueOf(sections, 'Tiempo', 'En la app:'), '200m');
    expect(valueOf(sections, 'Tiempo', 'Racha actual:'), '6d');
    expect(
      valueOf(sections, 'Detalle de partidas', 'Promedio de diamantes:'),
      '2,5',
    );
    expect(valueOf(sections, 'Tablero', 'Promedio del dado:'), '3,5');
    expect(valueOf(sections, 'Tienda', 'Cofre Básico:'), '2');
    expect(valueOf(sections, 'Social', 'Compañero más frecuente:'), 'Beto');
  });

  test('sin datos, los textos muestran una raya', () {
    final sections = presenter.sections(PlayerStats.empty);

    expect(
      valueOf(sections, 'Minijuegos por tipo', 'Favorito:'),
      StatsFormat.none,
    );
    expect(
      valueOf(sections, 'Social', 'Compañero más frecuente:'),
      StatsFormat.none,
    );
  });
}
