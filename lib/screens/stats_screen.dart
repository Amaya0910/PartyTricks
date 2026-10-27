import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/stats_presenter.dart';
import 'package:party_tricks/models/player_stats.dart';
import 'package:party_tricks/models/stats/stats_section.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/player_header.dart';
import 'package:party_tricks/widgets/stats_card.dart';

/// Estadísticas del jugador: todas las tarjetas en una lista que se recorre
/// hacia abajo. El fondo lo pone MainShellScreen.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final statsAsync = ref.watch(playerStatsProvider);

    return Column(
      children: [
        PlayerHeader(
          username: profile?.username ?? '',
          coins: profile?.coins ?? 0,
          diamonds: profile?.diamonds ?? 0,
        ),
        Expanded(
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const _Message(
              'No se pudieron cargar tus estadísticas. Revisa tu conexión.',
            ),
            data: (stats) => _StatsList(stats: stats),
          ),
        ),
      ],
    );
  }
}

class _StatsList extends StatelessWidget {
  const _StatsList({required this.stats});

  final PlayerStats stats;

  static const _presenter = StatsPresenter();

  static Color _colorFor(StatsTone tone) => switch (tone) {
    StatsTone.blue => AppColors.statsBlue,
    StatsTone.darkBlue => AppColors.statsDarkBlue,
    StatsTone.purple => AppColors.statsPurple,
  };

  @override
  Widget build(BuildContext context) {
    final sections = _presenter.sections(stats);
    // SafeArea inferior: deja espacio para la barra de navegación.
    return SafeArea(
      top: false,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 20),
        itemBuilder: (_, index) {
          final section = sections[index];
          return StatsCard(
            title: section.title,
            color: _colorFor(section.tone),
            rows: section.rows,
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.white),
        ),
      ),
    );
  }
}
