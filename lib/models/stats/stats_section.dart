/// Color de una tarjeta de Stats. La pantalla lo convierte en un color de
/// `AppColors`; así este modelo no depende de Flutter.
enum StatsTone { blue, darkBlue, purple }

/// Una fila: la etiqueta a la izquierda y el valor ya formateado a la derecha.
class StatsRow {
  const StatsRow(this.label, this.value);

  final String label;
  final String value;
}

/// Una tarjeta de la pantalla Stats.
class StatsSection {
  const StatsSection({
    required this.title,
    required this.tone,
    required this.rows,
  });

  final String title;
  final StatsTone tone;
  final List<StatsRow> rows;
}
