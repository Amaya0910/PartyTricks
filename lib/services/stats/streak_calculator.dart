import 'package:party_tricks/models/stats/time_stats.dart';

/// Racha de días seguidos abriendo la app.
///
/// No depende de Firebase ni de la hora real: recibe el momento como dato,
/// así se puede probar con cualquier fecha.
class StreakCalculator {
  const StreakCalculator();

  /// Día de [time] como `AAAA-MM-DD`, en la hora del celular.
  static String dayKey(DateTime time) {
    final local = time.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  /// Marca [now] como día activo y actualiza la racha:
  /// - Mismo día que el último: no cambia nada (devuelve el mismo objeto).
  /// - Día siguiente: la racha sube en 1.
  /// - Más de un día después (o sin días anteriores): la racha vuelve a 1.
  TimeStats registerDay(TimeStats stats, DateTime now) {
    final today = dayKey(now);
    final last = stats.lastActiveDay;
    final gap = last == null ? null : _daysBetween(last, today);

    // Mismo día, o una fecha anterior por un cambio de hora del celular.
    if (gap != null && gap <= 0) return stats;

    final current = gap == 1 ? stats.currentStreak + 1 : 1;
    return stats.copyWith(
      currentStreak: current,
      maxStreak: current > stats.maxStreak ? current : stats.maxStreak,
      lastActiveDay: today,
    );
  }

  /// Días entre dos claves `AAAA-MM-DD`. Se usa UTC para que el cambio de
  /// horario no deje días de 23 o 25 horas.
  int _daysBetween(String from, String to) {
    return _parse(to).difference(_parse(from)).inDays;
  }

  DateTime _parse(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }
}
