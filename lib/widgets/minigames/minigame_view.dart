import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:party_tricks/services/game_engine/minigames.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/minigames/balloon_game.dart';
import 'package:party_tricks/widgets/minigames/coin_rain_game.dart';
import 'package:party_tricks/widgets/minigames/color_trap_game.dart';
import 'package:party_tricks/widgets/minigames/dice_memory_game.dart';
import 'package:party_tricks/widgets/minigames/ghost_chair_game.dart';
import 'package:party_tricks/widgets/minigames/high_low_game.dart';
import 'package:party_tricks/widgets/minigames/quick_math_game.dart';
import 'package:party_tricks/widgets/minigames/reaction_game.dart';
import 'package:party_tricks/widgets/minigames/rhythm_game.dart';
import 'package:party_tricks/widgets/minigames/safe_lock_game.dart';
import 'package:party_tricks/widgets/minigames/secret_bid_game.dart';
import 'package:party_tricks/widgets/minigames/stopwatch_game.dart';
import 'package:party_tricks/widgets/minigames/wires_game.dart';

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
      MinigameType.rhythm => RhythmGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.diceMemory => DiceMemoryGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.coinRain => CoinRainGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.colorTrap => ColorTrapGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.quickMath => QuickMathGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.safeLock => SafeLockGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.wires => WiresGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.secretBid => SecretBidGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.highLow => HighLowGame(
        key: key,
        minigame: minigame,
        myId: myId,
        players: players,
        rules: rules,
        onPlay: onPlay,
      ),
      MinigameType.ghostChair => GhostChairGame(
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

/// Color e ícono de cada minijuego.
extension MinigameLook on MinigameType {
  Color get accent => switch (this) {
    MinigameType.stopwatch => AppColors.minigameStopwatch,
    MinigameType.reaction => AppColors.minigameReaction,
    MinigameType.balloon => AppColors.minigameBalloon,
    MinigameType.rhythm => AppColors.minigameRhythm,
    MinigameType.diceMemory => AppColors.minigameDiceMemory,
    MinigameType.coinRain => AppColors.minigameCoinRain,
    MinigameType.colorTrap => AppColors.minigameColorTrap,
    MinigameType.quickMath => AppColors.minigameQuickMath,
    MinigameType.safeLock => AppColors.minigameSafeLock,
    MinigameType.wires => AppColors.minigameWires,
    MinigameType.secretBid => AppColors.minigameSecretBid,
    MinigameType.highLow => AppColors.minigameHighLow,
    MinigameType.ghostChair => AppColors.minigameGhostChair,
  };

  IconData get icon => switch (this) {
    MinigameType.stopwatch => Icons.timer_rounded,
    MinigameType.reaction => Icons.bolt_rounded,
    MinigameType.balloon => Icons.celebration_rounded,
    MinigameType.rhythm => Icons.favorite_rounded,
    MinigameType.diceMemory => Icons.casino_rounded,
    MinigameType.coinRain => Icons.monetization_on_rounded,
    MinigameType.colorTrap => Icons.palette_rounded,
    MinigameType.quickMath => Icons.calculate_rounded,
    MinigameType.safeLock => Icons.lock_rounded,
    MinigameType.wires => Icons.content_cut_rounded,
    MinigameType.secretBid => Icons.toll_rounded,
    MinigameType.highLow => Icons.swap_vert_rounded,
    MinigameType.ghostChair => Icons.chair_rounded,
  };
}

/// Texto base de los minijuegos.
const minigameTextStyle = TextStyle(
  fontFamily: 'Inter',
  fontWeight: FontWeight.w600,
  color: AppColors.authText,
);

/// Mezcla [color] con blanco: 0 es blanco y 1 es el color tal cual.
Color minigameTint(Color color, double amount) =>
    Color.lerp(AppColors.white, color, amount)!;

/// Versión oscura de [color] para sombras, bordes y textos.
Color minigameShade(Color color, [double amount = 0.3]) =>
    Color.lerp(color, AppColors.characterOutline, amount)!;

/// Sombras sin difuminar alrededor de un texto: juntas forman un contorno de
/// [width] píxeles. Al ser parte del mismo texto, el contorno siempre coincide
/// con las letras, sea cual sea el tamaño de letra del teléfono.
List<Shadow> minigameOutline(Color color, double width) {
  const copies = 16;
  return [
    for (var i = 0; i < copies; i++)
      Shadow(
        color: color,
        offset: Offset.fromDirection(2 * math.pi * i / copies, width),
      ),
  ];
}

/// Pasa el color del minijuego a lo que hay dentro de la tarjeta (botones,
/// cuenta regresiva, píldoras) y si hay que dibujar en tamaño compacto.
class MinigameAccent extends InheritedWidget {
  const MinigameAccent({
    super.key,
    required this.color,
    this.compact = false,
    required super.child,
  });

  final Color color;

  /// Si el espacio es bajo y las piezas grandes (reloj, globo, recuadro)
  /// deben achicarse.
  final bool compact;

  static MinigameAccent? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MinigameAccent>();

  /// El color de la tarjeta, o el azul de los botones si no hay.
  static Color of(BuildContext context) =>
      _of(context)?.color ?? AppColors.minigameButton;

  static bool compactOf(BuildContext context) => _of(context)?.compact ?? false;

  @override
  bool updateShouldNotify(MinigameAccent oldWidget) =>
      color != oldWidget.color || compact != oldWidget.compact;
}

/// Tarjeta blanca con borde y cabecera del color del minijuego, como los
/// diálogos del resto de la app. Debajo del título va cómo se juega.
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

  static const double _radius = 26;
  static const double _border = 3;
  static const double _maxWidth = 380;
  static const double _margin = 16;

  /// Con menos alto que esto, las piezas se dibujan más chicas.
  static const double _compactBelow = 640;

  /// Más grande que esto, el texto ya no cabe en los recuadros de los juegos,
  /// aunque el teléfono tenga una letra enorme.
  static const double _maxTextScale = 1.15;

  @override
  Widget build(BuildContext context) {
    final accent = type.accent;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < _compactBelow;
        final width = (constraints.maxWidth - _margin * 2).clamp(
          0.0,
          _maxWidth,
        );
        // Si aun así no cabe, la tarjeta entera se achica: los botones
        // siempre quedan a la vista, sin tener que desplazarse.
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(_margin / 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _margin / 2,
                  _margin / 2,
                  _margin / 2,
                  _margin,
                ),
                child: SizedBox(
                  width: width,
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
                          blurRadius: 14,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_radius - _border),
                      child: MinigameAccent(
                        color: accent,
                        compact: compact,
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: _maxTextScale,
                          child: DefaultTextStyle.merge(
                            style: minigameTextStyle,
                            textAlign: TextAlign.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _CardHeader(type: type, compact: compact),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    14,
                                    compact ? 10 : 16,
                                    14,
                                    compact ? 14 : 20,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _Hint(
                                        text: instructions,
                                        compact: compact,
                                      ),
                                      SizedBox(height: compact ? 10 : 18),
                                      child,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Franja de color con el ícono y el nombre del minijuego.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.type, required this.compact});

  final MinigameType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = type.accent;
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 6 : 10, 16, compact ? 9 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [minigameTint(accent, 0.8), accent],
        ),
      ),
      child: Column(
        children: [
          Text(
            'MINIJUEGO DE ${type.category.title.toUpperCase()}',
            textAlign: TextAlign.center,
            style: minigameTextStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type.icon, color: AppColors.white, size: compact ? 24 : 28),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  type.title,
                  textAlign: TextAlign.center,
                  style: minigameTextStyle.copyWith(
                    fontSize: compact ? 22 : 26,
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
        ],
      ),
    );
  }
}

/// Recuadro suave con la bombilla y cómo se juega.
class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = MinigameAccent.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 7 : 10),
      decoration: BoxDecoration(
        color: minigameTint(accent, 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: minigameTint(accent, 0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded, color: accent, size: compact ? 18 : 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: minigameTextStyle.copyWith(
                fontSize: compact ? 12.5 : 13.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuenta regresiva antes de empezar ("Empieza en 3"): el número late en un
/// círculo del color del minijuego cada vez que cambia.
class MinigameIntro extends StatelessWidget {
  const MinigameIntro({super.key, required this.leftMs});

  final int leftMs;

  static const double _size = 112;
  static const double _compactSize = 88;

  @override
  Widget build(BuildContext context) {
    final size = MinigameAccent.compactOf(context) ? _compactSize : _size;
    final accent = MinigameAccent.of(context);
    final seconds = (leftMs / 1000).ceil();
    // De 1 (recién cambió el número) a 0 (a punto de cambiar).
    final beat = (leftMs % 1000) / 1000;
    final scale = 1 + 0.16 * Curves.easeIn.transform(beat);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Empieza en',
          style: minigameTextStyle.copyWith(
            fontSize: 16,
            color: AppColors.authHint,
          ),
        ),
        SizedBox.square(
          dimension: size * 1.4,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    colors: [minigameTint(accent, 0.65), accent],
                  ),
                  border: Border.all(color: AppColors.white, width: 5),
                  boxShadow: [
                    // Onda que se abre en cada número.
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3 * beat),
                      spreadRadius: 16 * (1 - beat),
                    ),
                    BoxShadow(
                      color: minigameShade(accent, 0.35),
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  '$seconds',
                  style: minigameTextStyle.copyWith(
                    fontSize: size * 0.52,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: minigameShade(accent, 0.5),
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón grande y gordito para jugar: tiene relieve y se hunde al tocarlo.
class MinigameButton extends StatefulWidget {
  const MinigameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.minWidth = 96,
    this.icon,
    this.fontSize = 26,
    this.height = 62,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Por defecto, el color del minijuego.
  final Color? color;
  final double minWidth;
  final IconData? icon;
  final double fontSize;
  final double height;

  @override
  State<MinigameButton> createState() => _MinigameButtonState();
}

class _MinigameButtonState extends State<MinigameButton> {
  static const double _depth = 6;

  /// Con colores más claros que esto, el texto blanco lleva contorno.
  static const double _lightColor = 0.45;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final base = widget.color ?? MinigameAccent.of(context);
    final color = enabled ? base : AppColors.sliderInactive;
    final sink = _pressed ? _depth - 2 : 0.0;
    final ink = minigameShade(color, 0.5);
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        // Estos tres no se quitan aunque el botón se desactive: si se quitaran
        // con el dedo encima, Flutter cancelaría el toque mientras arma la
        // pantalla, justo cuando no se permite usar setState.
        onTapDown: (_) => _setPressed(enabled),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: SizedBox(
          height: widget.height + _depth,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            margin: EdgeInsets.only(top: sink, bottom: _depth - sink),
            constraints: BoxConstraints(minWidth: widget.minWidth),
            padding: EdgeInsets.symmetric(
              horizontal: widget.minWidth == 0 ? 6 : 22,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [minigameTint(color, 0.7), color],
              ),
              border: Border.all(color: AppColors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: minigameShade(color, 0.35),
                  offset: Offset(0, _depth - sink),
                ),
                if (!_pressed)
                  const BoxShadow(
                    color: AppColors.pillShadow,
                    blurRadius: 8,
                    offset: Offset(0, 8),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: AppColors.white, size: 28),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      style: minigameTextStyle.copyWith(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        shadows: color.computeLuminance() > _lightColor
                            ? minigameOutline(ink, 1.5)
                            : [Shadow(color: ink, offset: const Offset(0, 2))],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Píldora con ícono y texto ("Objetivo: 7 s", "Infladas: 3").
class MinigamePill extends StatelessWidget {
  const MinigamePill({
    super.key,
    required this.text,
    this.icon,
    this.leading,
    this.color,
    this.fontSize = 16,
  });

  final String text;
  final IconData? icon;

  /// Se pone en lugar del ícono (por ejemplo, la moneda).
  final Widget? leading;

  /// Por defecto, el color del minijuego.
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? MinigameAccent.of(context);
    final leading = this.leading;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: minigameTint(color, 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, color: minigameShade(color, 0.15), size: fontSize + 4),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: minigameTextStyle.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: minigameShade(color, 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que te salió, grande y con un ícono ("Paraste en 6,80 s"). Aparece
/// con un pequeño rebote.
class MinigameFeedback extends StatelessWidget {
  const MinigameFeedback({
    super.key,
    required this.text,
    required this.icon,
    this.color,
  });

  final String text;
  final IconData icon;

  /// Por defecto, el color del minijuego.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? MinigameAccent.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: minigameTint(color, 0.16),
              border: Border.all(color: color, width: 3),
            ),
            child: Icon(icon, color: color, size: 38),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: minigameTextStyle.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: minigameShade(color, 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso para quien no juega este minijuego.
class MinigameSpectator extends StatelessWidget {
  const MinigameSpectator({super.key});

  @override
  Widget build(BuildContext context) {
    return const MinigameFeedback(
      text: 'Este minijuego lo ves desde fuera.',
      icon: Icons.visibility_rounded,
      color: AppColors.authHint,
    );
  }
}

/// "Esperando a los demás (2 de 3)", con un puntito por jugador que se
/// pinta cuando ya jugó.
class MinigameWaiting extends StatelessWidget {
  const MinigameWaiting({super.key, required this.minigame});

  final MinigameState minigame;

  @override
  Widget build(BuildContext context) {
    final accent = MinigameAccent.of(context);
    final total = minigame.players.length;
    final played = minigame.players.where(minigame.scores.containsKey).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.minigameSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < played ? accent : AppColors.minigameTrack,
                    border: Border.all(color: AppColors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.characterShadow,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Esperando a los demás ($played de $total)',
            textAlign: TextAlign.center,
            style: minigameTextStyle.copyWith(
              fontSize: 14,
              color: AppColors.authHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Segundos con dos decimales y coma: 11,84 s.
String formatSeconds(int ms) =>
    '${(ms / 1000).toStringAsFixed(2).replaceAll('.', ',')} s';
