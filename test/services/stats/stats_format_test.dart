import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/stats/stats_format.dart';

void main() {
  test('los segundos se muestran en minutos enteros', () {
    expect(StatsFormat.minutes(12000), '200m');
    expect(StatsFormat.minutes(59), '0m');
  });

  test('los días y el porcentaje llevan su sufijo', () {
    expect(StatsFormat.days(6), '6d');
    expect(StatsFormat.percent(50), '50%');
  });

  test('los decimales llevan un solo decimal y coma', () {
    expect(StatsFormat.decimal(3.5), '3,5');
    expect(StatsFormat.decimal(2), '2,0');
    expect(StatsFormat.decimal(10 / 3), '3,3');
  });

  test('un texto vacío o null se muestra como raya', () {
    expect(StatsFormat.text(null), StatsFormat.none);
    expect(StatsFormat.text(''), StatsFormat.none);
    expect(StatsFormat.text('Beto'), 'Beto');
  });
}
