import 'package:flutter/material.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/map_theme.dart';
import 'package:party_tricks/widgets/map/map_paths_painter.dart';

/// La parte fija del mapa: fondo, caminitos, plataformas con su marca,
/// tiendas y decoraciones. No cambia durante la partida, así que se dibuja
/// una sola vez (`RepaintBoundary`) y al mover la cámara solo se desplaza.
///
/// El camino, las marcas y sus colores salen del [theme] del mapa.
class MapScenery extends StatelessWidget {
  const MapScenery({
    super.key,
    required this.map,
    required this.board,
    required this.theme,
  });

  final BoardMap map;
  final BoardLayout board;
  final LoadedMapTheme theme;

  /// Tamaño de las marcas pintadas sobre el pasto.
  static const markSize = 192.0;

  /// La marca de bifurcación va debajo de la de la casilla, más grande,
  /// para que se vean las dos.
  static const forkMarkSize = markSize * 1.3;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.fromSize(
        size: map.size,
        child: Stack(
          children: [
            if (map.backgroundTiles.isEmpty)
              Positioned.fill(
                child: Image.asset(
                  map.background,
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) =>
                      ColoredBox(color: theme.colors.ground),
                ),
              )
            else ...[
              Positioned.fill(child: ColoredBox(color: theme.colors.ground)),
              for (final piece in map.backgroundTiles) _Sprite(sprite: piece),
            ],
            Positioned.fill(
              child: CustomPaint(
                painter: MapPathsPainter(map: map, board: board, theme: theme),
              ),
            ),
            for (final layer in _layersByDepth()) layer.widget,
          ],
        ),
      ),
    );
  }

  /// Plataformas (con su marca), tiendas y decoraciones, de arriba hacia
  /// abajo: lo de más abajo en la pantalla tapa a lo de arriba.
  List<_Layer> _layersByDepth() {
    final layers = <_Layer>[
      for (final object in map.objects)
        _Layer(object.depth, _Sprite(sprite: object)),
      for (final tile in map.tiles.values) ...[
        _Layer(tile.sprite.depth, _Sprite(sprite: tile.sprite)),
        // Justo encima de su plataforma.
        if (_forkMarkOf(tile) case final mark?)
          _Layer(tile.sprite.depth + 0.05, _mark(tile, mark, forkMarkSize)),
        if (_markOf(tile) case final mark?)
          _Layer(tile.sprite.depth + 0.1, _mark(tile, mark, markSize)),
      ],
    ];
    layers.sort((a, b) => a.depth.compareTo(b.depth));
    return layers;
  }

  Widget _mark(MapTile tile, String asset, double size) => Positioned(
    left: tile.anchor.dx - size / 2,
    top: tile.anchor.dy - size / 2,
    width: size,
    height: size,
    child: Image.asset(
      asset,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );

  BoardTile? _boardTile(MapTile tile) =>
      tile.id < board.tiles.length ? board.tile(tile.id) : null;

  String? _markOf(MapTile tile) => switch (_boardTile(tile)) {
    final boardTile? => theme.resolved.markFor(boardTile.type),
    null => null,
  };

  String? _forkMarkOf(MapTile tile) => _boardTile(tile)?.isFork ?? false
      ? theme.resolved[ThemeAsset.forkMark]
      : null;
}

class _Layer {
  const _Layer(this.depth, this.widget);

  final double depth;
  final Widget widget;
}

class _Sprite extends StatelessWidget {
  const _Sprite({required this.sprite});

  final MapSprite sprite;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      sprite.asset,
      width: sprite.rect.width,
      height: sprite.rect.height,
      fit: BoxFit.fill,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    return Positioned.fromRect(
      rect: sprite.rect,
      child: sprite.flipX ? Transform.flip(flipX: true, child: image) : image,
    );
  }
}
