import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/board_walk.dart';
import 'package:party_tricks/services/map/coin_tracker.dart';
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
/// - Las casillas positivas tienen una moneda. Cuando tu personaje pasa por
///   ahí, crece, sube y desaparece solo para ti; vuelve en la siguiente
///   ronda.
/// - En una bifurcación, en tu turno, salen dos flechas para elegir camino.
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
  /// Ancho del mundo que se ve en la pantalla al empezar (unas 4 casillas).
  /// Más grande = más lejos; desde unos 2700 ya se ve casi todo el mapa.
  static const _visibleWidth = 1100.0;
  static const _hopDuration = Duration(milliseconds: 320);
  static const _hopHeight = 70.0;
  static const _tokenSize = 130.0;

  /// Separación entre jugadores que están en la misma casilla.
  static const _sideBySide = 110.0;
  static const _arrowSize = 128.0;

  /// Distancia del centro de la bifurcación a cada flecha.
  static const _arrowDistance = 230.0;

  static const _coinSize = 110.0;
  static const _diamondSize = 150.0;

  /// Qué tan arriba del centro del pasto flotan la moneda y el diamante.
  static const _floatHeight = 40.0;
  static const _coinPop = Duration(milliseconds: 550);

  final _camera = TransformationController();

  /// Un caminante por jugador, en el orden de turnos.
  final Map<String, _Walker> _walkers = {};

  late final _coins = CoinTracker([
    for (final tile in widget.board.tiles)
      if (tile.type == TileType.positive) tile.id,
  ])..onRound(widget.state.round);

  /// Monedas que se están desapareciendo ahora.
  final Map<int, AnimationController> _popping = {};

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
    _coins.onRound(widget.state.round);
    _syncWalkers();
  }

  @override
  void dispose() {
    for (final walker in _walkers.values) {
      walker.dispose();
    }
    for (final pop in _popping.values) {
      pop.dispose();
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
          onArrive: id == widget.myId ? _collectCoin : null,
          onIdle: () => setState(() {}), // Para mostrar las flechas.
        ),
      );
      walker.walkTo(position, walk);
    }
  }

  void _followMe() => _follow(_feetOf(widget.myId));

  /// Tu personaje llegó a [tile]: si hay moneda, la hace desaparecer.
  void _collectCoin(int tile) {
    if (!_coins.collect(tile)) return;
    final pop = AnimationController(vsync: this, duration: _coinPop);
    pop.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      setState(() => _popping.remove(tile));
      // Se libera después del cuadro, fuera de su propio aviso.
      WidgetsBinding.instance.addPostFrameCallback((_) => pop.dispose());
    });
    setState(() => _popping[tile] = pop);
    pop.forward();
  }

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
    double clamp(double value, double view, double content) =>
        content <= view
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
    _camera.value = Matrix4.diagonal3Values(scale, scale, scale)
      ..setTranslationRaw(dx, dy, 0);
  }

  void _placeCamera(Size viewport) {
    _viewport = viewport;
    if (_placedCamera || viewport.isEmpty) return;
    _placedCamera = true;
    // Se aplica después del primer cuadro, cuando el visor ya está armado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scale = max(viewport.width / _visibleWidth, _minScale(viewport));
      // El zoom va también en z: getMaxScaleOnAxis() mira los tres ejes y,
      // con z en 1, devolvería 1 y la cámara volvería al tamaño normal.
      _camera.value = Matrix4.diagonal3Values(scale, scale, scale);
      if (_walkers.containsKey(widget.myId)) _followMe();
    });
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
                  ..._coinWidgets(),
                  if (_diamondAnchor() case final diamond?)
                    Positioned(
                      left: diamond.dx - _diamondSize / 2,
                      top: diamond.dy - _floatHeight - _diamondSize,
                      width: _diamondSize,
                      height: _diamondSize,
                      child: Image.asset(
                        MapAssets.diamond,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.diamond,
                          size: _diamondSize,
                          color: AppColors.diamond,
                        ),
                      ),
                    ),
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

  /// Las monedas que se ven y las que están desapareciendo. La del diamante
  /// no se dibuja para que no se encimen.
  List<Widget> _coinWidgets() {
    final diamondTile = widget.state.diamondTileId;
    return [
      for (final tile in _coins.tiles)
        if (tile != diamondTile && widget.map.tiles.containsKey(tile))
          if (_popping[tile] case final pop?)
            AnimatedBuilder(
              key: ValueKey('moneda-$tile'),
              animation: pop,
              builder: (context, child) {
                final t = Curves.easeOut.transform(pop.value);
                return _coinAt(
                  tile,
                  scale: 1 + 0.5 * t,
                  rise: 90 * t,
                  opacity: 1 - t,
                  child: child!,
                );
              },
              child: const _Coin(),
            )
          else if (_coins.isVisible(tile))
            _coinAt(tile, child: const _Coin()),
    ];
  }

  Widget _coinAt(
    int tile, {
    required Widget child,
    double scale = 1,
    double rise = 0,
    double opacity = 1,
  }) {
    final anchor = _anchorOf(tile);
    return Positioned(
      key: ValueKey('moneda-$tile'),
      left: anchor.dx - _coinSize / 2,
      top: anchor.dy - _floatHeight - _coinSize - rise,
      width: _coinSize,
      height: _coinSize,
      child: Opacity(
        opacity: opacity.clamp(0, 1).toDouble(),
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }

  Offset? _diamondAnchor() {
    final id = widget.state.diamondTileId;
    return widget.map.tiles[id]?.anchor;
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
    this.onArrive,
  }) : tile = start,
       _from = anchorOf(start),
       _to = anchorOf(start) {
    controller
      ..addListener(() => onHop?.call())
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        onArrive?.call(tile);
        _nextHop();
      });
  }

  final Offset Function(int tileId) anchorOf;
  final AnimationController controller;
  final VoidCallback onIdle;

  /// Solo para tu personaje: la cámara lo sigue.
  final VoidCallback? onHop;

  /// Solo para tu personaje: recoge la moneda de cada casilla que pisa.
  final void Function(int tile)? onArrive;

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

/// Moneda flotando sobre una casilla positiva.
class _Coin extends StatelessWidget {
  const _Coin();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      MapAssets.coin,
      errorBuilder: (_, _, _) => const Icon(
        Icons.monetization_on,
        size: _BoardMapViewState._coinSize,
        color: AppColors.coin,
      ),
    );
  }
}
