import 'dart:async';

import 'package:flutter/material.dart';
import 'package:party_tricks/screens/admin/admin_samples.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/services/game_engine/random_source.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/minigame_result_overlay.dart';
import 'package:party_tricks/widgets/minigames/minigame_view.dart';

/// Práctica de minijuegos del panel de administración: se juega en este
/// teléfono contra dos rivales de mentira, con las mismas reglas
/// ([MinigameJudge]) y las mismas pantallas que en la partida. No se
/// conecta a Firebase ni guarda nada.
class MinigamePracticeScreen extends StatefulWidget {
  const MinigamePracticeScreen({super.key, this.random});

  /// Para las pruebas; por defecto, al azar.
  final RandomSource? random;

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const MinigamePracticeScreen());

  @override
  State<MinigamePracticeScreen> createState() => _MinigamePracticeScreenState();
}

class _MinigamePracticeScreenState extends State<MinigamePracticeScreen> {
  static const _rules = MinigameRules();

  /// Lo que tardan los rivales en inflar o cortar un cable en su turno.
  static const _botPumpDelay = Duration(milliseconds: 1100);

  /// Lo que tardan los rivales en elegir en los juegos por vueltas.
  static const _botPickDelay = Duration(milliseconds: 1400);

  /// Alto del panel de abajo del tablero, para ver la tarjeta compacta.
  static const _boardPanelHeight = 230.0;

  late final RandomSource _random = widget.random ?? DartRandomSource();
  late final MinigameJudge _judge = MinigameJudge(random: _random);

  final List<Timer> _timers = [];
  MinigameState? _state;
  MinigameResult? _result;
  int _round = 0;
  bool _withPanel = true;

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _after(Duration delay, VoidCallback action) {
    _timers.add(
      Timer(delay, () {
        if (mounted) action();
      }),
    );
  }

  void _start(MinigameType type) {
    _cancelTimers();
    _round++;
    final outcome = _judge.start(type, _round, AdminSamples.players);
    setState(() {
      _state = outcome.state;
      if (outcome.result != null) _result = outcome.result;
    });
    final state = outcome.state;
    if (state != null) _scheduleBots(state);
  }

  /// Los rivales juegan solos: en Para el Tiempo paran cerca del objetivo,
  /// en Reacción tocan entre 200 y 450 ms después del "¡YA!", en el Globo
  /// Bomba inflan de 1 a 3 en su turno, en los juegos con puntaje terminan
  /// con uno razonable y en los demás eligen al azar.
  void _scheduleBots(MinigameState state) {
    switch (state.type) {
      case MinigameType.stopwatch:
        for (final bot in AdminSamples.bots) {
          final score = state.targetMs + _random.nextInt(-900, 900);
          _after(
            Duration(milliseconds: _rules.introMs + score),
            () => _apply(bot, score),
          );
        }
      case MinigameType.reaction:
        for (final bot in AdminSamples.bots) {
          final score = _random.nextInt(200, 450);
          _after(
            Duration(milliseconds: _rules.introMs + state.delayMs + score),
            () => _apply(bot, score),
          );
        }
      case MinigameType.balloon:
        _scheduleBalloonTurn(state);
      case MinigameType.rhythm:
        _botsScore(state, 9000, 15, 130);
      case MinigameType.diceMemory:
        _botsScore(state, 14000, 3, 8);
      case MinigameType.coinRain:
        _botsScore(state, _rules.coinRainMs, 8, 30);
      case MinigameType.colorTrap:
        _botsScore(state, 16000, 500, 1700);
      case MinigameType.quickMath:
        _botsScore(state, _rules.quickMathMs, 40, 170);
      case MinigameType.safeLock:
        _botsScore(state, 10000, 60, 320);
      case MinigameType.wires:
        _scheduleWireTurn(state);
      case MinigameType.secretBid:
      case MinigameType.highLow:
      case MinigameType.ghostChair:
        _scheduleRound(state);
    }
  }

  /// Los rivales terminan a los [ms] de empezar con un puntaje entre [low] y
  /// [high].
  void _botsScore(MinigameState state, int ms, int low, int high) {
    for (final bot in AdminSamples.bots) {
      final score = _random.nextInt(low, high);
      _after(
        Duration(milliseconds: _rules.introMs + ms),
        () => _apply(bot, score),
      );
    }
  }

  /// Cables Rojos: si le toca a un rival, corta uno al azar.
  void _scheduleWireTurn(MinigameState state) {
    final current = state.balloonPlayer;
    if (current == AdminSamples.me) return;
    final wait = state.step == 0 ? _rules.introMs : 0;
    final boom = state.stage > 0 && state.cut.isEmpty ? _rules.wiresBoomMs : 0;
    final step = state.step;
    _after(Duration(milliseconds: wait + boom) + _botPumpDelay, () {
      final now = _state;
      if (now == null || now.step != step) return;
      final left = [
        for (var wire = 0; wire < now.wires; wire++)
          if (!now.cut.contains(wire)) wire,
      ];
      _apply(current, left[_random.nextInt(0, left.length - 1)]);
    });
  }

  /// Por vueltas: cada rival que sigue en juego elige después de un momento.
  void _scheduleRound(MinigameState state) {
    final wait = state.stage == 0
        ? _rules.introMs
        : _rules.revealMs(state.type);
    for (final bot in AdminSamples.bots) {
      if (!state.alive.contains(bot)) continue;
      final stage = state.stage;
      _after(Duration(milliseconds: wait) + _botPickDelay, () {
        final now = _state;
        if (now == null || now.stage != stage) return;
        _apply(bot, MinigamePick.encode(stage, _botPick(now, bot)));
      });
    }
  }

  int _botPick(MinigameState state, String bot) {
    return switch (state.type) {
      MinigameType.secretBid => _random.nextInt(
        0,
        (state.chips[bot] ?? 0).clamp(0, _rules.maxBid),
      ),
      MinigameType.highLow => state.card > _rules.maxCard ~/ 2 ? 0 : 1,
      _ => _random.nextInt(0, _rules.chairs - 1),
    };
  }

  void _scheduleBalloonTurn(MinigameState state) {
    final current = state.balloonPlayer;
    final wait = state.step == 0 ? _rules.introMs : 0;
    if (current != AdminSamples.me) {
      _after(
        Duration(milliseconds: wait) + _botPumpDelay,
        () => _apply(current, _random.nextInt(1, _rules.maxPumps)),
      );
      return;
    }
    // Si no inflas a tiempo, se infla 1 por ti (como hace el anfitrión).
    final step = state.step;
    _after(Duration(milliseconds: wait + _rules.balloonTurnMs), () {
      final now = _state;
      if (now == null || now.step != step) return;
      _handle(_judge.timeout(now, step));
    });
  }

  void _apply(String playerId, int score) {
    final state = _state;
    if (state == null) return;
    try {
      _handle(_judge.play(state, playerId, score));
    } on StateError {
      // Jugada vieja o repetida: se ignora, como en la partida.
    }
  }

  void _handle(MinigameOutcome outcome) {
    setState(() {
      _state = outcome.state;
      if (outcome.result != null) _result = outcome.result;
    });
    final next = outcome.state;
    if (next == null) {
      _cancelTimers();
    } else if (next.ending) {
      // Ya se sabe cómo termina: se deja ver y se cierra.
      final step = next.step;
      _after(_rules.timeLimit(next), () {
        final now = _state;
        if (now != null && now.step == step) _handle(_judge.timeout(now, step));
      });
    } else if (next.type == MinigameType.balloon) {
      _scheduleBalloonTurn(next);
    } else if (next.type == MinigameType.wires) {
      _scheduleWireTurn(next);
    } else if (next.type.playsInRounds && next.scores.isEmpty) {
      _scheduleRound(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              withPanel: _withPanel,
              onPanelChanged: (value) => setState(() => _withPanel = value),
            ),
            _Picker(current: state?.type, onPick: _start),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (state != null)
                    MinigameView(
                      minigame: state,
                      myId: AdminSamples.me,
                      players: AdminSamples.minigamePlayers,
                      onPlay: (score) => _apply(AdminSamples.me, score),
                    )
                  else
                    const _Empty(),
                  MinigameResultOverlay(
                    result: _result,
                    players: AdminSamples.minigamePlayers,
                    coins: 10,
                  ),
                ],
              ),
            ),
            if (_withPanel)
              Container(
                height: _boardPanelHeight,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.boardPanel,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Aquí va el panel del tablero\n(para ver el espacio real)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.authHint),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.withPanel, required this.onPanelChanged});

  final bool withPanel;
  final ValueChanged<bool> onPanelChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.settingsReload,
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Volver'),
          ),
          const Spacer(),
          const Text(
            'Panel',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          Switch(
            value: withPanel,
            onChanged: onPanelChanged,
            activeTrackColor: AppColors.settingsOn,
          ),
        ],
      ),
    );
  }
}

/// Un botón por minijuego. Tocar uno empieza (o reinicia) ese minijuego.
class _Picker extends StatelessWidget {
  const _Picker({required this.current, required this.onPick});

  final MinigameType? current;
  final ValueChanged<MinigameType> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        children: [
          for (final type in MinigameType.values) ...[
            if (type != MinigameType.values.first) const SizedBox(width: 8),
            SizedBox(
              width: 104,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: type == current
                      ? type.accent
                      : minigameTint(type.accent, 0.55),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.white, width: 2),
                  ),
                ),
                onPressed: () => onPick(type),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 22),
                    Text(
                      type.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.boardPanel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Elige un minijuego para practicar.\n'
          'Juegas tú contra Beto y Caro (de mentira).',
          textAlign: TextAlign.center,
          style: minigameTextStyle.copyWith(fontSize: 16),
        ),
      ),
    );
  }
}
