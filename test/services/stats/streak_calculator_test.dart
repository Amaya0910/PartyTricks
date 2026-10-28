import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/stats/time_stats.dart';
import 'package:party_tricks/services/stats/streak_calculator.dart';

void main() {
  const calculator = StreakCalculator();

  TimeStats lastActive(String day, {int current = 3, int max = 5}) {
    return TimeStats(
      currentStreak: current,
      maxStreak: max,
      lastActiveDay: day,
    );
  }

  test('dayKey arma AAAA-MM-DD con ceros a la izquierda', () {
    expect(StreakCalculator.dayKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });

  test('el primer día activo empieza la racha en 1', () {
    final next = calculator.registerDay(
      const TimeStats(),
      DateTime(2026, 10, 27),
    );

    expect(next.currentStreak, 1);
    expect(next.maxStreak, 1);
    expect(next.lastActiveDay, '2026-10-27');
  });

  test('el mismo día no cambia nada', () {
    final stats = lastActive('2026-10-27');

    final next = calculator.registerDay(stats, DateTime(2026, 10, 27, 22));

    expect(identical(next, stats), isTrue);
  });

  test('el día siguiente suma 1 a la racha', () {
    final next = calculator.registerDay(
      lastActive('2026-10-26'),
      DateTime(2026, 10, 27, 8),
    );

    expect(next.currentStreak, 4);
    expect(next.maxStreak, 5);
    expect(next.lastActiveDay, '2026-10-27');
  });

  test('si la racha pasa la máxima, la máxima sube también', () {
    final next = calculator.registerDay(
      lastActive('2026-10-26', current: 5, max: 5),
      DateTime(2026, 10, 27),
    );

    expect(next.currentStreak, 6);
    expect(next.maxStreak, 6);
  });

  test('si se salta un día, la racha vuelve a 1 y la máxima se queda', () {
    final next = calculator.registerDay(
      lastActive('2026-10-24'),
      DateTime(2026, 10, 27),
    );

    expect(next.currentStreak, 1);
    expect(next.maxStreak, 5);
  });

  test('cuenta bien el cambio de mes y de año', () {
    final next = calculator.registerDay(
      lastActive('2026-12-31'),
      DateTime(2027, 1, 1),
    );

    expect(next.currentStreak, 4);
  });

  test('una fecha anterior (reloj cambiado) no cambia nada', () {
    final stats = lastActive('2026-10-27');

    final next = calculator.registerDay(stats, DateTime(2026, 10, 20));

    expect(identical(next, stats), isTrue);
  });

  test('no toca el tiempo en la app', () {
    final next = calculator.registerDay(
      const TimeStats(secondsInApp: 120, secondsPlaying: 60),
      DateTime(2026, 10, 27),
    );

    expect(next.secondsInApp, 120);
    expect(next.secondsPlaying, 60);
  });
}
