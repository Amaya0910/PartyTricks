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
import 'package:party_tricks/widgets/profile_avatar.dart';

/// El mapa dibujado de la partida.
///
/// - Se puede mover y hacer zoom; la cámara sigue a tu personaje cuando
///   camina.
/// - Se ven todos los jugadores. Avanzan saltando de casilla en casilla y,
///   si comparten casilla, se ponen uno al lado del otro.
/// - En una bifurcación, en tu turno, salen dos flechas para elegir camino.
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
  static const _tokenSize = 130.0;

  /// Separación entre jugadores que están en la misma casilla.
  static const _sideBySide = 110.0;
  static const _arrowSize = 128.0;
  static const _trapSize = 90.0;

  /// Distancia del centro de la bifurcación a cada flecha.
  static const _arrowDistance = 230.0;

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
        return ClipRect(
          child: InteractiveViewer(
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
                  ..._arrows(),
                  ..._tokens(),
                ],
              ),
            ),
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
            return Positioned(
              left: feet.dx - _tokenSize / 2,
              top: feet.dy - _tokenSize,
              width: _tokenSize,
              height: _tokenSize,
              child: child!,
            );
          },
          child: _Token(color: _colorOf(id)),
        ),
    ];
  }

  Color _colorOf(String id) {
    final index = widget.state.turnOrder.indexOf(id);
    const colors = AppColors.players;
    return colors[(index < 0 ? 0 : index) % colors.length];
  }

  /// Las dos flechas de la bifurcación, solo en tu turno y ya parado ahí.
  List<Widget> _arrows() {
    final state = widget.state;
    final me = _walkers[widget.myId];
    final choosing =
        state.phase == GamePhase.choosingBranch &&
        state.currentPlayerId == widget.myId &&
        me != null &&
        !_anyWalking;
    if (!choosing) return const [];
    final fork = _anchorOf(me.tile);
    final next = widget.board.tile(me.tile).next;
    return [
      for (final (branch, tileId) in next.indexed)
        _arrow(fork, _anchorOf(tileId), () => widget.onChooseBranch(branch)),
    ];
  }

  Widget _arrow(Offset from, Offset to, VoidCallback onTap) {
    final direction = to - from;
    final unit = direction.distance == 0
        ? const Offset(1, 0)
        : direction / direction.distance;
    final center = from + unit * _arrowDistance;
    return Positioned(
      left: center.dx - _arrowSize / 2,
      top: center.dy - _arrowSize / 2,
      width: _arrowSize,
      height: _arrowSize,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: atan2(unit.dy, unit.dx),
          child: Image.asset(
            MapAssets.branchArrow,
            errorBuilder: (_, _, _) => const Icon(
              Icons.arrow_forward,
              size: _arrowSize,
              color: AppColors.settingsAccent,
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

  void dispose() => controller.dispose();
}

/// Un jugador, provisional hasta tener las hojas de animación: su foto en
/// un círculo con su color.
class _Token extends StatelessWidget {
  const _Token({required this.color});

  final Color color;

  /// Grosor del aro de color.
  static const _ring = 8.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_ring),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const ProfileAvatar(
        size: _BoardMapViewState._tokenSize - _ring * 2,
      ),
    );
  }
}
