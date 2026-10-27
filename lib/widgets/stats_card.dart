import 'package:flutter/material.dart';
import 'package:party_tricks/models/stats/stats_section.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Tarjeta de la pantalla Stats: cabecera de color con el [title] y las
/// filas en un recuadro blanco. Solo dibuja; recibe los textos ya listos.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.title,
    required this.color,
    required this.rows,
  });

  final String title;
  final Color color;
  final List<StatsRow> rows;

  static const double _radius = 20;
  static const double _border = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pillShadow,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(_border, 0, _border, _border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(_radius - _border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [for (final row in rows) _Row(row: row)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final StatsRow row;

  static const _style = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.statsText,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(row.label, style: _style)),
          const SizedBox(width: 12),
          Text(row.value, style: _style),
        ],
      ),
    );
  }
}
