import 'package:flutter/material.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/map/map_assets.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Resultado del minijuego sobre el mapa: quién ganó, lo que hizo cada uno
/// y, si hubo empate, el desempate con el dado. Se quita solo y no tapa los
/// toques.
///
/// Solo aparece cuando termina un minijuego nuevo: al entrar (o volver) a
/// la partida no se repite el anterior.
class MinigameResultOverlay extends StatefulWidget {
  const MinigameResultOverlay({
    super.key,
    required this.result,
    required this.players,
    required this.coins,
  });

  final MinigameResult? result;
  final MinigamePlayers players;

  /// Monedas que gana cada ganador.
  final int coins;

  /// Cuánto se ve.
  static const duration = Duration(seconds: 5);

  @override
  State<MinigameResultOverlay> createState() => _MinigameResultOverlayState();
}

class _MinigameResultOverlayState extends State<MinigameResultOverlay>
    with SingleTickerProviderStateMixin {
  /// La tarjeta entra con un rebote al principio y la última parte se
  /// desvanece.
  static const _popEnd = 0.08;
  static const _fadeStart = 0.85;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: MinigameResultOverlay.duration,
        )..addStatusListener((_) {
          if (mounted) setState(() {});
        });
  }

  @override
  void didUpdateWidget(MinigameResultOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final result = widget.result;
    final old = oldWidget.result;
    if (result != null &&
        (old == null || old.round != result.round || old.type != result.type)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (result == null || !_controller.isAnimating) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final opacity = t < _fadeStart
              ? 1.0
              : 1 - (t - _fadeStart) / (1 - _fadeStart);
          final scale = t < _popEnd
              ? 0.8 + 0.2 * Curves.easeOutBack.transform(t / _popEnd)
              : 1.0;
          return Opacity(
            opacity: opacity.clamp(0, 1).toDouble(),
            child: ColoredBox(
              color: AppColors.diceScrim,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: Center(
          child: SingleChildScrollView(
            child: MinigameResultCard(
              result: result,
              players: widget.players,
              coins: widget.coins,
            ),
          ),
        ),
      ),
    );
  }
}

/// La tarjeta con el resultado: cabecera del color del minijuego, franja
/// dorada con quién ganó y una fila por jugador.
class MinigameResultCard extends StatelessWidget {
  const MinigameResultCard({
    super.key,
    required this.result,
    required this.players,
    required this.coins,
  });

  final MinigameResult result;
  final MinigamePlayers players;
  final int coins;

  static const double _radius = 26;
  static const double _border = 3;

  @override
  Widget build(BuildContext context) {
    final accent = result.type.accent;
    final winners = result.winnerIds.map(players.nameOf).toList();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: accent, width: _border),
            boxShadow: [
              BoxShadow(
                color: minigameShade(accent, 0.4),
                offset: const Offset(0, 6),
              ),
              const BoxShadow(
                color: AppColors.pillShadow,
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius - _border),
            child: MinigameAccent(
              color: accent,
              child: DefaultTextStyle.merge(
                style: minigameTextStyle,
                textAlign: TextAlign.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(type: result.type),
                    _WinnerBand(winners: winners, coins: coins),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (result.type == MinigameType.stopwatch) ...[
                            MinigamePill(
                              text:
                                  'Objetivo: ${formatSeconds(result.targetMs)}',
                              icon: Icons.flag_rounded,
                              fontSize: 14,
                            ),
                            const SizedBox(height: 10),
                          ],
                          for (final line in _lines())
                            _ScoreRow(
                              text: line.text,
                              name: players.nameOf(line.id),
                              color: players.colorOf(line.id),
                              winner: result.winnerIds.contains(line.id),
                              out: line.out,
                            ),
                          if (result.tiebreak.isNotEmpty)
                            _Tiebreak(result: result, players: players),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Lo que hizo cada uno, según el minijuego.
  List<({String id, String text, bool out})> _lines() {
    final fate = switch (result.type) {
      MinigameType.balloon => 'reventó el globo',
      MinigameType.wires => 'hizo explotar la bomba',
      MinigameType.highLow => 'falló la carta',
      MinigameType.ghostChair => 'se quedó sin vidas',
      _ => null,
    };
    if (fate != null) {
      return [for (final id in result.out) (id: id, text: fate, out: true)];
    }
    return [
      for (final MapEntry(key: id, value: score) in result.scores.entries)
        (id: id, text: _score(score), out: score == MinigameRules.noScore),
    ];
  }

  String _score(int score) {
    if (score == MinigameRules.noScore) return 'no cuenta';
    return switch (result.type) {
      MinigameType.stopwatch => formatSeconds(score),
      MinigameType.rhythm => '$score ms de desvío',
      MinigameType.diceMemory => '$score dados',
      MinigameType.secretBid => _bid(score),
      MinigameType.reaction => '$score ms',
      _ => '$score puntos',
    };
  }

  /// Puja Secreta: el puntaje guarda las vueltas ganadas y las fichas.
  String _bid(int score) {
    final won = score ~/ 100;
    final chips = score % 100;
    final rounds = won == 1 ? '1 puja ganada' : '$won pujas ganadas';
    return '$rounds y $chips fichas';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.type});

  final MinigameType type;

  @override
  Widget build(BuildContext context) {
    final accent = type.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [minigameTint(accent, 0.8), accent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type.icon, color: AppColors.white, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              type.title,
              textAlign: TextAlign.center,
              style: minigameTextStyle.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                shadows: [
                  Shadow(
                    color: minigameShade(accent, 0.5),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trofeo, quién ganó y las monedas que se lleva.
class _WinnerBand extends StatelessWidget {
  const _WinnerBand({required this.winners, required this.coins});

  final List<String> winners;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final nobody = winners.isEmpty;
    final color = nobody ? AppColors.authHint : AppColors.minigameWinner;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: nobody ? AppColors.minigameSoft : AppColors.minigameWinnerSoft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nobody ? AppColors.minigameTrack : AppColors.medalGold,
              border: Border.all(color: AppColors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: minigameShade(color, 0.3),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              nobody
                  ? Icons.sentiment_neutral_rounded
                  : Icons.emoji_events_rounded,
              color: AppColors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nobody ? 'Nadie ganó' : 'Ganó ${winners.join(' y ')}',
            textAlign: TextAlign.center,
            style: minigameTextStyle.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: minigameShade(color, 0.1),
            ),
          ),
          if (!nobody) ...[
            const SizedBox(height: 6),
            MinigamePill(
              text: '+$coins monedas',
              color: AppColors.coin,
              fontSize: 15,
              leading: Image.asset(
                MapAssets.coin,
                width: 20,
                height: 20,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.coin,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Ana: 7,30 s" con el color del jugador; quien ganó lleva estrella y
/// fondo dorado, y a quien no le contó se le ve apagado.
class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.text,
    required this.name,
    required this.color,
    required this.winner,
    required this.out,
  });

  final String text;
  final String name;
  final Color color;
  final bool winner;
  final bool out;

  @override
  Widget build(BuildContext context) {
    final ink = out ? AppColors.authHint : AppColors.authText;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: winner ? AppColors.minigameWinnerSoft : AppColors.minigameSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: winner ? AppColors.medalGold : AppColors.white,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ': $text'),
                ],
              ),
              textAlign: TextAlign.left,
              style: minigameTextStyle.copyWith(fontSize: 15, color: ink),
            ),
          ),
          if (winner)
            const Icon(Icons.star_rounded, color: AppColors.medalGold, size: 22)
          else if (out)
            const Icon(
              Icons.close_rounded,
              color: AppColors.minigameOut,
              size: 20,
            ),
        ],
      ),
    );
  }
}

/// Los dados que se tiraron para desempatar.
class _Tiebreak extends StatelessWidget {
  const _Tiebreak({required this.result, required this.players});

  final MinigameResult result;
  final MinigamePlayers players;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.minigameTrack, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.casino_rounded,
                color: AppColors.authHint,
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Empate: se desempató con el dado',
                  style: minigameTextStyle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final MapEntry(key: id, value: rolls) in result.tiebreak.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      players.nameOf(id),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: minigameTextStyle.copyWith(fontSize: 14),
                    ),
                  ),
                  for (final roll in rolls) ...[
                    const SizedBox(width: 4),
                    _SmallDie(value: roll),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Dado chiquito con la imagen de arte o, si falta, el número.
class _SmallDie extends StatelessWidget {
  const _SmallDie({required this.value});

  final int value;

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      MapAssets.dice(value),
      width: _size,
      height: _size,
      errorBuilder: (_, _, _) => Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.minigameTrack, width: 2),
        ),
        child: Text(
          '$value',
          style: minigameTextStyle.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
