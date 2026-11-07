import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/map/map_assets.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/flip_card.dart';
import 'package:party_tricks/widgets/minigames/minigame_kit.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Mayor o Menor: sale una carta y todos apuestan en secreto si la siguiente
/// será mayor o menor. Quien falla queda fuera; si fallan todos, siguen
/// todos. Gana el último.
class HighLowGame extends MinigameWidget {
  const HighLowGame({
    super.key,
    required super.minigame,
    required super.myId,
    required super.players,
    required super.rules,
    required super.onPlay,
  });

  @override
  State<HighLowGame> createState() => _HighLowGameState();
}

class _HighLowGameState extends State<HighLowGame>
    with SingleTickerProviderStateMixin, MinigameClock, MinigameRounds {
  /// Cuánto se espera antes de voltear la carta y cuánto tarda en voltearse.
  static const int _flipAtMs = 500;
  static const int _verdictMs = 1200;

  static const int _low = 0;
  static const int _high = 1;

  /// Lo que eligió este teléfono en esta vuelta.
  int? _myPick;

  /// Los que salieron en la vuelta que se está viendo.
  List<String> _justOut = const [];

  @override
  void onReveal(MinigameState before) {
    _myPick = null;
    _justOut = [
      for (final id in game.out)
        if (!before.out.contains(id)) id,
    ];
    HapticFeedback.lightImpact();
  }

  void _choose(int value) {
    _myPick = value;
    pick(value);
  }

  @override
  Widget build(BuildContext context) {
    return MinigameCard(
      type: MinigameType.highLow,
      instructions:
          '¿La siguiente carta será mayor o menor? Si fallas, quedas fuera.',
      child: inIntro
          ? MinigameIntro(leftMs: rules.introMs - elapsedMs)
          : _body(),
    );
  }

  Widget _body() {
    final revealing = this.revealing;
    final verdict = revealing && revealClockMs >= _verdictMs;
    // Los que salieron se apagan cuando ya se vio la carta.
    final waitingOut = revealing && !verdict ? _justOut.toSet() : <String>{};
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigameArena(
          height: 214,
          compactHeight: 184,
          colors: const [AppColors.feltLight, AppColors.feltDark],
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Table(
                left: revealing ? game.previousCard : game.card,
                right: revealing ? game.card : null,
                turned: revealing && revealClockMs >= _flipAtMs,
                stage: game.stage,
              ),
              if (verdict && game.card > game.previousCard)
                const _Verdict(text: '¡Mayor!')
              else if (verdict)
                const _Verdict(text: '¡Menor!'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 74, child: Center(child: _bottom(verdict))),
        MinigameStandings(
          game: _visible(waitingOut),
          players: widget.players,
          trailing: (id) => _mark(id, revealing, verdict),
        ),
      ],
    );
  }

  /// La partida como debe verse: quienes acaban de salir siguen jugando hasta
  /// que se vea la carta.
  MinigameState _visible(Set<String> waitingOut) {
    if (waitingOut.isEmpty) return game;
    return game.copyWith(
      out: [
        for (final id in game.out)
          if (!waitingOut.contains(id)) id,
      ],
    );
  }

  Widget? _mark(String id, bool revealing, bool verdict) {
    if (revealing) {
      if (!verdict || !game.picks.containsKey(id)) return null;
      final won = game.card > game.previousCard ? _high : _low;
      final right = game.picks[id] == won;
      return Icon(
        right ? Icons.check_circle_rounded : Icons.cancel_rounded,
        size: 15,
        color: right ? AppColors.reactionGo : AppColors.minigameOut,
      );
    }
    return game.scores.containsKey(id)
        ? const Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: AppColors.authAccent,
          )
        : null;
  }

  Widget _bottom(bool verdict) {
    if (revealing) {
      if (!verdict) return const _Hint(text: 'Veamos...');
      final names = _justOut.map(widget.players.nameOf).join(' y ');
      return _justOut.isEmpty
          ? const MinigameAlert(
              text: 'Nadie sale',
              icon: Icons.favorite_rounded,
              color: AppColors.reactionGo,
            )
          : MinigameAlert(text: 'Fuera: $names');
    }
    if (!active) return const _Hint(text: 'Estás fuera: mira cómo acaban');
    if (hasPicked) {
      final mine = _myPick ?? game.scores[widget.myId];
      return _Hint(text: mine == _low ? 'Apostaste Menor' : 'Apostaste Mayor');
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinigameTimeBar(left: choiceLeftMs / rules.highLowChoiceMs, height: 6),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: MinigameButton(
                label: 'Menor',
                icon: Icons.arrow_downward_rounded,
                color: AppColors.minigameOut,
                minWidth: 0,
                fontSize: 20,
                height: 50,
                onPressed: () => _choose(_low),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MinigameButton(
                label: 'Mayor',
                icon: Icons.arrow_upward_rounded,
                color: AppColors.highLowUp,
                minWidth: 0,
                fontSize: 20,
                height: 50,
                onPressed: () => _choose(_high),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: minigameTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.authHint,
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // Abajo, como un sello: los números de las cartas se siguen viendo.
    return Align(
      alignment: const Alignment(0, 0.88),
      child: Transform.rotate(
        angle: -0.08,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 2.2, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInCubic,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: MinigameOutlinedText(
            text,
            fontSize: 30,
            color: AppColors.medalGold,
            outlineWidth: 6,
          ),
        ),
      ),
    );
  }
}

/// Las dos cartas: la que se ve y la del mazo, que se voltea al revelar.
class _Table extends StatelessWidget {
  const _Table({
    required this.left,
    required this.right,
    required this.turned,
    required this.stage,
  });

  final int left;

  /// La carta nueva, o null mientras se apuesta.
  final int? right;
  final bool turned;
  final int stage;

  @override
  Widget build(BuildContext context) {
    final compact = MinigameAccent.compactOf(context);
    final height = compact ? 132.0 : 156.0;
    final width = height * 0.7;
    final right = this.right;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: _Card(value: left),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.double_arrow_rounded,
            color: AppColors.pillBackground,
            size: 30,
          ),
        ),
        SizedBox(
          width: width,
          height: height,
          child: FlipCard(
            key: ValueKey(stage),
            showBack: turned,
            duration: const Duration(milliseconds: 460),
            front: const _CardBack(),
            back: right == null ? const _CardBack() : _Card(value: right),
          ),
        ),
      ],
    );
  }
}

/// Una carta con su número y monedas en las esquinas.
class _Card extends StatelessWidget {
  const _Card({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final height = box.maxHeight;
        return Container(
          decoration: _cardBox(AppColors.white),
          child: Stack(
            children: [
              Positioned(top: 6, left: 6, child: _coin(height)),
              Positioned(bottom: 6, right: 6, child: _coin(height)),
              Center(
                child: Text(
                  '$value',
                  style: minigameTextStyle.copyWith(
                    fontSize: height * 0.46,
                    fontWeight: FontWeight.w700,
                    color: AppColors.feltDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _coin(double height) => Image.asset(
    MapAssets.coin,
    width: height * 0.14,
    height: height * 0.14,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        return Container(
          decoration: _cardBox(AppColors.minigameHighLow),
          padding: const EdgeInsets.all(7),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '?',
                style: minigameTextStyle.copyWith(
                  fontSize: box.maxHeight * 0.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

BoxDecoration _cardBox(Color color) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: AppColors.white, width: 3),
  boxShadow: const [
    BoxShadow(color: AppColors.characterShadow, offset: Offset(0, 4)),
  ],
);
