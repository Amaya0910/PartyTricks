/// Textos de los números de la pantalla Stats, como en el mockup.
class StatsFormat {
  const StatsFormat._();

  /// Se muestra cuando todavía no hay dato (por ejemplo, sin minijuego
  /// favorito).
  static const none = '—';

  /// Segundos a minutos enteros: `200m`.
  static String minutes(int seconds) => '${seconds ~/ 60}m';

  /// Días: `6d`.
  static String days(int days) => '${days}d';

  /// Porcentaje: `50%`.
  static String percent(int value) => '$value%';

  /// Un decimal con coma, como se escribe en Colombia: `3,5`.
  static String decimal(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');

  /// El texto, o [none] si no hay.
  static String text(String? value) =>
      value == null || value.isEmpty ? none : value;
}
