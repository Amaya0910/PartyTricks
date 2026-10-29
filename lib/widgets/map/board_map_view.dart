import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/board_walk.dart';
import 'package:party_tricks/services/map/map_assets.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/map/map_scenery.dart';
import 'package:party_tricks/widgets/party_character.dart';

/// El mapa dibujado de la partida.
///
/// - Se puede mover y hacer zoom; la cámara sigue a tu personaje cuando
///   camina.
/// - Se ven todos los jugadores. Avanzan saltando de casilla en casilla y,
///   si comparten casilla, se ponen uno al lado del otro.
/// - En una bifurcación, en tu turno, salen dos flechas para elegir camino.
///   Se dibujan sobre la pantalla y no sobre el mapa, así que siempre se
///   ven completas y del mismo tamaño, sin importar el zoom.
/// - Las trampas se ven en su casilla con el color de quien las puso.
class BoardMapView extends StatefulWidget {
  const BoardMapView({
    super.key,
    required this.map,
    required this.board,
    required this.pathTexture,
    required this.state,
    required this.myId,
    required this.onChooseBranch,
  });

  final BoardMap map;
  final BoardLayout board;
  final ui.Image pathTexture;
  final GameState state;
  final String myId;

  /// 0 = la primera casilla de `next` (camino principal), 1 = la segunda.
  final void Function(int branch) onChooseBranch;

  @override
  State<BoardMapView> createState() => _BoardMapViewState();
}

class _BoardMapViewState extends State<BoardMapView>
    with TickerProviderStateMixin {
  /// Ancho del mundo que se ve en la pantalla al empezar (unas 5 casillas).
  static const _visibleWidth = 2000.0;
  static const _hopDuration = Duration(milliseconds: 320);
  static const _hopHeight = 70.0;

  /// Alto del personaje en el mapa (arte_imagenes.md, sección 7).
  static const _characterHeight = 210.0;

  /// Separación entre jugadores que están en la misma casilla.
  static const _sideBySide = 120.0;
  static const _trapSize = 90.0;

  /// Distancia en el mapa del centro de la bifurcación a cada flecha.
  static const _arrowDistance = 230.0;

  /// Tamaño de las flechas en la pantalla: una parte del lado más corto,
  /// entre un mínimo para poder tocarlas y un máximo para no tapar el mapa.
  static const _arrowScreenShare = 0.2;
  static const _arrowMinSize = 56.0;
  static const _arrowMaxSize = 96.0;

  /// Espacio entre las flechas y el borde de la pantalla.
  static const _arrowMargin = 8.0;

  final _camera = TransformationController();

  /// Un caminante por jugador, en el orden de turnos.
  final Map<String, _Walker> _walkers = {};

  Size _viewport = Size.zero;
  bool _placedCamera = false;

  bool get _anyWalking => _walkers.values.any((walker) => walker.walking);

  Offset _anchorOf(int tileId) =>
      widget.map.tiles[tileId]?.anchor ?? widget.map.size.center(Offset.zero);

  @override
  void initState() {
    super.initState();
    _syncWalkers();
  }

  @override
  void didUpdateWidget(BoardMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWalkers();
  }

  @override
  void dispose() {
    for (final walker in _walkers.values) {
      walker.dispose();
    }
    _camera.dispose();
    super.dispose();
  }

  /// Crea los caminantes que faltan y les da su nueva casilla.
  void _syncWalkers() {
    final walk = BoardWalk(widget.board);
    for (final id in widget.state.turnOrder) {
      final position = widget.state.players[id]?.position ?? 0;
      final walker = _walkers.putIfAbsent(
        id,
        () => _Walker(
          start: position,
          anchorOf: _anchorOf,
          controller: AnimationController(vsync: this, duration: _hopDuration),
          onHop: id == widget.myId ? _followMe : null,
          onIdle: () => setState(() {}), // Para mostrar las flechas.
        ),
      );
      walker.walkTo(position, walk);
    }
  }

  void _followMe() => _follow(_feetOf(widget.myId));

  /// Dónde van los pies de un jugador ahora: con el saltito entre casillas y
  /// corrido a un lado si comparte casilla con otros.
  Offset _feetOf(String id) {
    final walker = _walkers[id]!;
    final mates = [
      for (final other in widget.state.turnOrder)
        if (_walkers[other]?.tile == walker.tile) other,
    ];
    final index = mates.indexOf(id);
    final shift = (index - (mates.length - 1) / 2) * _sideBySide;
    return walker.position.translate(shift, 0);
  }

  /// Centra la cámara en [world] sin cambiar el zoom ni salirse del mapa.
  void _follow(Offset world) {
    if (_viewport.isEmpty) return;
    final scale = _camera.value.getMaxScaleOnAxis();
    final mapSize = widget.map.size * scale;
    double clamp(double value, double view, double content) => content <= view
        ? (view - content) / 2
        : value.clamp(view - content, 0).toDouble();
    final dx = clamp(
      _viewport.width / 2 - world.dx * scale,
      _viewport.width,
      mapSize.width,
    );
    final dy = clamp(
      _viewport.height / 2 - world.dy * scale,
      _viewport.height,
      mapSize.height,
    );
    _camera.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(dx, dy, 0);
  }

  void _placeCamera(Size viewport) {
    _viewport = viewport;
    if (_placedCamera || viewport.isEmpty) return;
    _placedCamera = true;
    final scale = max(viewport.width / _visibleWidth, _minScale(viewport));
    _camera.value = Matrix4.diagonal3Values(scale, scale, 1);
    if (_walkers.containsKey(widget.myId)) _followMe();
  }

  /// Lo más lejos que se puede alejar: el mapa llena la pantalla.
  double _minScale(Size viewport) {
    if (viewport.isEmpty) return 0.1;
    return max(
      viewport.width / widget.map.size.width,
      viewport.height / widget.map.size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        _placeCamera(viewport);
        final arrows = _arrowTargets();
        return ClipRect(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _camera,
                constrained: false,
                minScale: _minScale(viewport),
                maxScale: 1.2,
                child: SizedBox.fromSize(
                  size: widget.map.size,
                  child: Stack(
                    children: [
                      MapScenery(
                        map: widget.map,
                        board: widget.board,
                        pathTexture: widget.pathTexture,
                      ),
                      if (_diamondAnchor() case final diamond?)
                        Positioned(
                          left: diamond.dx - 60,
                          top: diamond.dy - 130,
                          child: const Icon(
                            Icons.diamond,
                            size: 120,
                            color: AppColors.diamond,
                          ),
                        ),
                      ..._traps(),
                      ..._tokens(),
                    ],
                  ),
                ),
              ),
              if (arrows.isNotEmpty)
                // Siguen a la cámara cuando mueves o acercas el mapa.
                AnimatedBuilder(
                  animation: _camera,
                  builder: (context, _) =>
                      Stack(children: _arrows(viewport, arrows)),
                ),
            ],
          ),
        );
      },
    );
  }

  Offset? _diamondAnchor() {
    final id = widget.state.diamondTileId;
    return widget.map.tiles[id]?.anchor;
  }

  /// Las trampas puestas, con el color de quien las puso.
  List<Widget> _traps() {
    return [
      for (final MapEntry(key: tileId, value: ownerId)
          in widget.state.traps.entries)
        if (widget.map.tiles[tileId]?.anchor case final anchor?)
          Positioned(
            left: anchor.dx - _trapSize / 2,
            top: anchor.dy - _trapSize / 2,
            child: Icon(
              Icons.dangerous,
              size: _trapSize,
              color: _colorOf(ownerId),
            ),
          ),
    ];
  }

  /// Los jugadores, con el tuyo encima de los demás.
  List<Widget> _tokens() {
    final order = widget.state.turnOrder;
    final ids = [
      for (final id in order)
        if (id != widget.myId) id,
      if (order.contains(widget.myId)) widget.myId,
    ];
    final moving = Listenable.merge([
      for (final walker in _walkers.values) walker.controller,
    ]);
    return [
      for (final id in ids)
        AnimatedBuilder(
          key: ValueKey(id),
          animation: moving,
          builder: (context, child) {
            final feet = _feetOf(id);
            const width = _characterHeight * PartyCharacter.aspectRatio;
            return Positioned(
              left: feet.dx - width / 2,
              top: feet.dy - _characterHeight,
              width: width,
              height: _characterHeight,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: _walkers[id]!.stretch,
                child: child,
              ),
            );
          },
          child: PartyCharacter(color: _colorOf(id), height: _characterHeight),
        ),
    ];
  }

  Color _colorOf(String id) {
    final index = widget.state.turnOrder.indexOf(id);
    const colors = AppColors.players;
    return colors[(index < 0 ? 0 : index) % colors.length];
  }

  /// Hacia dónde apunta cada flecha de la bifurcación (bifurcación y
  /// casilla siguiente), solo en tu turno y ya parado ahí. Vacío si no toca
  /// elegir.
  List<(Offset, Offset)> _arrowTargets() {
    final state = widget.state;
    final me = _walkers[widget.myId];
    final choosing =
        state.phase == GamePhase.choosingBranch &&
        state.currentPlayerId == widget.myId &&
        me != null &&
        !_anyWalking;
    if (!choosing) return const [];
    final fork = _anchorOf(me.tile);
    return [
      for (final tileId in widget.board.tile(me.tile).next)
        (fork, _anchorOf(tileId)),
    ];
  }

  /// Las flechas en la pantalla: salen de la bifurcación hacia cada camino
  /// y, si quedarían fuera (zoom, mapa movido o pantalla pequeña), se
  /// acercan al borde para que siempre se vean completas.
  List<Widget> _arrows(Size viewport, List<(Offset, Offset)> targets) {
    if (viewport.isEmpty) return const [];
    final matrix = _camera.value;
    final scale = matrix.getMaxScaleOnAxis();
    final size = min(
      (viewport.shortestSide * _arrowScreenShare)
          .clamp(_arrowMinSize, _arrowMaxSize)
          .toDouble(),
      viewport.shortestSide - _arrowMargin * 2,
    );
    if (size <= 0) return const [];
    final distance = max(_arrowDistance * scale, size * 0.9 + 16);
    final placed = <(Offset, Offset)>[]; // (centro, dirección)
    for (final (from, to) in targets) {
      final fork = MatrixUtils.transformPoint(matrix, from);
      final direction = MatrixUtils.transformPoint(matrix, to) - fork;
      final unit = direction.distance == 0
          ? const Offset(1, 0)
          : direction / direction.distance;
      placed.add((_insideScreen(fork + unit * distance, size, viewport), unit));
    }
    // Si al pegarse al borde quedan encimadas, se separan.
    if (placed.length == 2) {
      final (a, unitA) = placed[0];
      final (b, unitB) = placed[1];
      if ((a - b).distance < size * 1.1) {
        final apart = (b - a).distance == 0
            ? Offset(-unitA.dy, unitA.dx)
            : (b - a) / (b - a).distance;
        final middle = (a + b) / 2;
        placed[0] = (
          _insideScreen(middle - apart * size * 0.6, size, viewport),
          unitA,
        );
        placed[1] = (
          _insideScreen(middle + apart * size * 0.6, size, viewport),
          unitB,
        );
      }
    }
    return [
      for (final (branch, (center, unit)) in placed.indexed)
        _arrow(center, unit, size, () => widget.onChooseBranch(branch)),
    ];
  }

  Offset _insideScreen(Offset center, double size, Size viewport) {
    final half = size / 2 + _arrowMargin;
    return Offset(
      center.dx.clamp(half, max(half, viewport.width - half)).toDouble(),
      center.dy.clamp(half, max(half, viewport.height - half)).toDouble(),
    );
  }

  Widget _arrow(Offset center, Offset unit, double size, VoidCallback onTap) {
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Aparece creciendo un poco para que se note.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          builder: (context, grow, child) =>
              Transform.scale(scale: grow, child: child),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.boardPanel,
              boxShadow: [
                BoxShadow(color: AppColors.characterShadow, blurRadius: 6),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.1),
              child: Transform.rotate(
                angle: atan2(unit.dy, unit.dx),
                child: Image.asset(
                  MapAssets.branchArrow,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.arrow_forward,
                    size: size * 0.8,
                    color: AppColors.settingsAccent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lleva a un jugador de casilla en casilla con un saltito.
class _Walker {
  _Walker({
    required int start,
    required this.anchorOf,
    required this.controller,
    required this.onIdle,
    this.onHop,
  }) : tile = start,
       _from = anchorOf(start),
       _to = anchorOf(start) {
    controller
      ..addListener(() => onHop?.call())
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _nextHop();
      });
  }

  final Offset Function(int tileId) anchorOf;
  final AnimationController controller;
  final VoidCallback onIdle;

  /// Solo para tu personaje: la cámara lo sigue.
  final VoidCallback? onHop;

  /// Casilla a la que llegó o hacia la que está saltando.
  int tile;
  final List<int> _pending = [];
  Offset _from;
  Offset _to;

  bool get walking => controller.isAnimating || _pending.isNotEmpty;

  /// Agrega las casillas hasta [target] y empieza a caminar si estaba quieto.
  void walkTo(int target, BoardWalk walk) {
    final last = _pending.isNotEmpty ? _pending.last : tile;
    if (target == last) return;
    _pending.addAll(walk.between(last, target));
    if (!controller.isAnimating) _nextHop();
  }

  void _nextHop() {
    if (_pending.isEmpty) {
      onIdle();
      return;
    }
    final next = _pending.removeAt(0);
    _from = anchorOf(tile);
    _to = anchorOf(next);
    tile = next;
    controller.forward(from: 0);
  }

  /// Dónde van los pies ahora, con el saltito entre casillas.
  Offset get position {
    final t = Curves.easeInOut.transform(controller.value);
    final base = Offset.lerp(_from, _to, t)!;
    return base.translate(
      0,
      -sin(pi * controller.value) * _BoardMapViewState._hopHeight,
    );
  }

  /// Se estira en el aire y se aplasta un poco al caer, para que el salto
  /// se note. Quieto no cambia nada.
  Matrix4 get stretch {
    final t = controller.value;
    if (!controller.isAnimating || t == 0) return Matrix4.identity();
    final air = sin(pi * t);
    final landing = t > 0.85 ? sin(pi * (t - 0.85) / 0.15) : 0.0;
    final scaleY = 1 + 0.08 * air - 0.12 * landing;
    return Matrix4.diagonal3Values(2 - scaleY, scaleY, 1);
  }

  void dispose() => controller.dispose();
}
