import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/balloon_game.dart';
import 'package:party_tricks/widgets/minigames/reaction_game.dart';
import 'package:party_tricks/widgets/minigames/stopwatch_game.dart';

/// Quién juega: nombre y color de cada jugador, para todos los minijuegos.
class MinigamePlayers {
  const MinigamePlayers({required this.names, required this.colors});

  final Map<String, String> names;
  final Map<String, Color> colors;

  String nameOf(String id) => names[id] ?? id;
  Color colorOf(String id) => colors[id] ?? AppColors.blueStrong;
}

/// El minijuego de la ronda en este teléfono. Elige la pantalla según el
/// tipo y la vuelve a armar en cada minijuego nuevo.
///
/// Cada teléfono mide su propio tiempo desde que muestra el minijuego, así
/// no importa si los relojes de los teléfonos no coinciden. Solo manda su
/// puntaje con [onPlay]; el anfitrión decide quién gana.
class MinigameView extends StatelessWidget {
  const MinigameView({
    super.key,
    required this.minigame,
    required this.myId,
    required this.players,
    required this.onPlay,
    this.rules = const MinigameRules(),
  });

  final MinigameState minigame;
  final String myId;
  final MinigamePlayers players;
  final MinigameRules rules;
  final void Function(int score) onPlay;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey('${minigame.round}/${minigame.type.name}');
    return switch (minigame.type) {
      MinigameType.stopwatch => StopwatchGame(
        key: key,
        minigame: minigame,
        myId: myId,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.reaction => ReactionGame(
        key: key,
        minigame: minigame,
        myId: myId,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.balloon => BalloonGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
    };
  }
}

/// Reloj de un minijuego: cuenta los ms desde que se mostró, con cada
/// cuadro de la pantalla. En las pruebas avanza con `tester.pump`.
///
/// Se usa así: `with SingleTickerProviderStateMixin, MinigameClock`.
mixin MinigameClock<T extends StatefulWidget> on State<T>, TickerProvider {
  late final Ticker _ticker;
  int _elapsedMs = 0;

  /// ms desde que se mostró el minijuego.
  int get elapsedMs => _elapsedMs;

  /// Se llama en cada cuadro, después de actualizar [elapsedMs].
  void onClock() {}

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _elapsedMs = elapsed.inMilliseconds);
      onClock();
    })..start();
  }

  /// Deja de contar cuando ya no hace falta (ya jugó).
  void stopClock() {
    if (_ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// Tarjeta común: título del minijuego, cómo se juega y el contenido.
class MinigameCard extends StatelessWidget {
  const MinigameCard({
    super.key,
    required this.type,
    required this.instructions,
    required this.child,
  });

  final MinigameType type;
  final String instructions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si la pantalla es muy baja, se desplaza en vez de desbordarse.
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.minigamePanel,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(instructions, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Cuenta regresiva antes de empezar ("Empieza en 3").
class MinigameIntro extends StatelessWidget {
  const MinigameIntro({super.key, required this.leftMs});

  final int leftMs;

  @override
  Widget build(BuildContext context) {
    final seconds = (leftMs / 1000).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Empieza en'),
        Text(
          '$seconds',
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Botón grande para jugar.
class MinigameButton extends StatelessWidget {
  const MinigameButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(120, 64),
        backgroundColor: AppColors.minigameButton,
        textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// "Esperando a los demás (2 de 3)".
class MinigameWaiting extends StatelessWidget {
  const MinigameWaiting({super.key, required this.minigame});

  final MinigameState minigame;

  @override
  Widget build(BuildContext context) {
    final played = minigame.players.where(minigame.scores.containsKey).length;
    return Text(
      'Esperando a los demás ($played de ${minigame.players.length})',
      textAlign: TextAlign.center,
    );
  }
}

/// Segundos con dos decimales y coma: 11,84 s.
String formatSeconds(int ms) =>
    '${(ms / 1000).toStringAsFixed(2).replaceAll('.', ',')} s';
