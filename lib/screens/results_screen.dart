import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/game_engine/match_results.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/app_background.dart';
import 'package:party_tricks/widgets/fx/idle_motion.dart';
import 'package:party_tricks/widgets/fx/party_button.dart';
import 'package:party_tricks/widgets/fx/pop_in.dart';
import 'package:party_tricks/widgets/party_panel.dart';
import 'package:party_tricks/widgets/party_pill.dart';

/// Pantalla final de la partida: el ganador, la clasificación completa, los
/// diamantes finales, lo que te llevas (XP, monedas y diamantes) y cómo te
/// fue en el tablero.
///
/// Solo dibuja. Los resultados salen de [MatchResultsBuilder], los mismos
/// que se guardan en las estadísticas y en el registro de la partida.
class ResultsScreen extends StatelessWidget {
  ResultsScreen({
    super.key,
    required this.game,
    required this.myId,
    required this.onExit,
    MatchResultsBuilder results = const MatchResultsBuilder(),
  }) : results = results.build(game);

  /// La partida ya terminada.
  final GameState game;
  final String myId;
  final MatchResults results;

  /// Volver al inicio.
  final VoidCallback onExit;

  Color _colorOf(String id) {
    final index = game.turnOrder.indexOf(id);
    const colors = AppColors.players;
    return colors[(index < 0 ? 0 : index) % colors.length];
  }

  String _names(List<String> ids) {
    if (ids.isEmpty) return 'Nadie';
    return ids.map((id) => game.players[id]?.username ?? id).join(' y ');
  }

  @override
  Widget build(BuildContext context) {
    final mine = results.of(myId);
    // Cada bloque entra un poco después del anterior.
    var order = 0;
    Widget enter(Widget child) => PopIn.staggered(
      index: order++,
      base: const Duration(milliseconds: 120),
      child: child,
    );
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      enter(
                        _WinnerBanner(
                          title: _winnerTitle(),
                          subtitle: 'Partida de ${results.rounds} rondas',
                        ),
                      ),
                      if (mine != null) ...[
                        const SizedBox(height: 14),
                        enter(_Rewards(result: mine)),
                      ],
                      const SizedBox(height: 14),
                      enter(
                        _Section(
                          title: 'Clasificación',
                          children: [
                            for (final result in results.ranking)
                              _RankingRow(
                                result: result,
                                color: _colorOf(result.id),
                                isMe: result.id == myId,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      enter(
                        _Section(
                          title: 'Diamantes finales',
                          children: [
                            for (final entry in results.awards.entries)
                              _StatRow(
                                label: entry.key.label,
                                value: _names(entry.value),
                              ),
                          ],
                        ),
                      ),
                      if (mine != null) ...[
                        const SizedBox(height: 14),
                        enter(
                          _Section(
                            title: 'Tu partida',
                            children: _myStats(mine.player),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: PartyButton(
                    label: 'Volver al inicio',
                    icon: Icons.home_rounded,
                    onPressed: onExit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _winnerTitle() {
    final ids = results.winnerIds;
    if (ids.contains(myId)) {
      return results.isTie ? '¡Ganaste en empate!' : '¡Ganaste!';
    }
    return results.isTie
        ? '¡Empate! Ganan ${_names(ids)}'
        : '¡Ganó ${_names(ids)}!';
  }

  List<Widget> _myStats(PlayerState p) {
    return [
      _StatRow(label: 'Dados lanzados', value: '${p.diceRolled}'),
      _StatRow(label: 'Suma de los dados', value: '${p.diceTotal}'),
      _StatRow(label: 'Casillas positivas', value: '${p.positiveTiles}'),
      _StatRow(label: 'Casillas negativas', value: '${p.negativeTiles}'),
      _StatRow(label: 'Casillas especiales', value: '${p.specialTiles}'),
      _StatRow(label: 'Atajos tomados', value: '${p.shortcutsTaken}'),
      _StatRow(label: 'Vueltas al mapa', value: '${p.laps}'),
      _StatRow(label: 'Diamantes del mapa', value: '${p.mapDiamonds}'),
      _StatRow(
        label: 'Minijuegos ganados',
        value: '${p.minigamesWon} de ${results.rounds}',
      ),
      _StatRow(label: 'Compras en tiendas', value: '${p.purchases}'),
      _StatRow(label: 'Ítems usados', value: '${p.itemsUsed}'),
    ];
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PartyPanel(
      child: Column(
        children: [
          // El trofeo cae con un rebote y luego flota.
          const PopIn(
            from: Offset(0, -1),
            startScale: 0.3,
            duration: Duration(milliseconds: 800),
            child: Floating(
              child: Icon(
                Icons.emoji_events,
                size: 80,
                color: AppColors.medalGold,
                shadows: [
                  Shadow(color: AppColors.medalBronze, offset: Offset(0, 4)),
                ],
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.authAccent,
              shadows: [
                Shadow(color: AppColors.headerBorder, offset: Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Lo que te llevas a tu cuenta.
class _Rewards extends StatelessWidget {
  const _Rewards({required this.result});

  final PlayerResult result;

  @override
  Widget build(BuildContext context) {
    return PartyPanel(
      child: Column(
        children: [
          Text(
            'Quedaste en el puesto ${result.place}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            // Los premios saltan uno detrás de otro.
            children: [
              for (final (index, reward) in [
                _Reward(
                  icon: Icons.star,
                  color: AppColors.medalGold,
                  value: '+${result.experience} XP',
                ),
                _Reward(
                  icon: Icons.monetization_on,
                  color: AppColors.coin,
                  value: '+${result.coins}',
                ),
                _Reward(
                  icon: Icons.diamond,
                  color: AppColors.diamond,
                  value: '+${result.diamonds}',
                ),
              ].indexed)
                PopIn.staggered(
                  index: index,
                  base: const Duration(milliseconds: 400),
                  startScale: 0.3,
                  from: Offset.zero,
                  duration: const Duration(milliseconds: 650),
                  child: reward,
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Las monedas y los diamantes pasan a tu cuenta.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward({required this.icon, required this.color, required this.value});

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 38,
          shadows: const [
            Shadow(color: AppColors.pillShadow, offset: Offset(0, 2)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PartyPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PartyPill(label: title, fontSize: 18),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.result,
    required this.color,
    required this.isMe,
  });

  final PlayerResult result;
  final Color color;
  final bool isMe;

  Color? get _medal => switch (result.place) {
    1 => AppColors.medalGold,
    2 => AppColors.medalSilver,
    3 => AppColors.medalBronze,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final medal = _medal;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isMe ? AppColors.resultsMine : null,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: AppColors.blueMain, width: 2) : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: medal ?? color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.pillShadow,
                blurRadius: 0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${result.place}',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: AppColors.pillShadow, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(backgroundColor: color, radius: 6),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isMe ? '${result.username} (tú)' : result.username,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Text('+${result.experience} XP'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, color: AppColors.coin, size: 18),
            Text(' ${result.coins}   '),
            const Icon(Icons.diamond, color: AppColors.diamond, size: 18),
            Text(' ${result.diamonds}'),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
