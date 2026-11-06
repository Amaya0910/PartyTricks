import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/admin/app_overview.dart';
import 'package:party_tricks/models/stats/stats_section.dart';
import 'package:party_tricks/screens/admin/admin_page.dart';
import 'package:party_tricks/services/admin/admin_providers.dart';
import 'package:party_tricks/services/results/match_results_document.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/stats_card.dart';

/// Estadísticas de toda la app: cuentas, partidas, economía y tiempo de
/// uso. Se calculan en Firestore al abrir la pantalla.
class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const AdminStatsScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(appOverviewProvider);
    return AdminPage(
      title: 'Estadísticas de la app',
      children: [
        ...switch (overview) {
          AsyncData(:final value) => _cards(value),
          AsyncError(:final error) => [_Message(text: '$error')],
          _ => const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        },
        Center(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.settingsReload,
            ),
            onPressed: () => ref.invalidate(appOverviewProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
          ),
        ),
      ],
    );
  }

  List<Widget> _cards(AppOverview o) {
    return [
      StatsCard(
        title: 'Jugadores',
        color: AppColors.statsBlue,
        rows: [
          StatsRow('Cuentas', '${o.users}'),
          StatsRow('XP entre todos', '${o.totalExperience}'),
          StatsRow('Tiempo en la app', _hours(o.secondsInApp)),
        ],
      ),
      StatsCard(
        title: 'Partidas',
        color: AppColors.statsDarkBlue,
        rows: [
          StatsRow('Terminadas', '${o.matches}'),
          StatsRow('Públicas', '${o.publicMatches}'),
          StatsRow(
            'Por cuenta',
            o.matchesPerUser.toStringAsFixed(1).replaceAll('.', ','),
          ),
          StatsRow('Minijuegos ganados', '${o.minigamesWon}'),
        ],
      ),
      StatsCard(
        title: 'Economía',
        color: AppColors.statsPurple,
        rows: [
          StatsRow('Monedas guardadas', '${o.totalCoins}'),
          StatsRow('Diamantes guardados', '${o.totalDiamonds}'),
          StatsRow('Diamantes gastados en cofres', '${o.diamondsSpent}'),
        ],
      ),
      StatsCard(
        title: 'Últimas partidas',
        color: AppColors.statsBlue,
        rows: o.recentMatches.isEmpty
            ? const [StatsRow('Todavía no hay', '')]
            : [for (final match in o.recentMatches) _matchRow(match)],
      ),
    ];
  }

  StatsRow _matchRow(MatchRecord match) {
    final names = {for (final p in match.players) p.uid: p.username};
    final winners = match.winnerIds.map((id) => names[id] ?? id).join(' y ');
    return StatsRow(
      'Ganó ${winners.isEmpty ? 'nadie' : winners}',
      '${match.players.length} jug. · ${match.rounds} r.',
    );
  }

  /// 5400 s -> "1,5 h".
  String _hours(int seconds) =>
      '${(seconds / 3600).toStringAsFixed(1).replaceAll('.', ',')} h';
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.authError,
        ),
      ),
    );
  }
}
