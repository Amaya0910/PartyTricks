import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/map_assets.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/map/map_paths_painter.dart';

/// La parte fija del mapa: fondo, caminitos, plataformas con su marca,
/// tiendas y decoraciones. No cambia durante la partida, así que se dibuja
/// una sola vez (`RepaintBoundary`) y al mover la cámara solo se desplaza.
class MapScenery extends StatelessWidget {
  const MapScenery({
    super.key,
    required this.map,
    required this.board,
    required this.pathTexture,
  });

  final BoardMap map;
  final BoardLayout board;
  final ui.Image pathTexture;

  /// Tamaño de las marcas pintadas sobre el pasto.
  static const markSize = 192.0;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.fromSize(
        size: map.size,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                map.background,
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.tilePositive),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: MapPathsPainter(
                  map: map,
                  board: board,
                  texture: pathTexture,
                ),
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
        if (_markOf(tile) case final mark?)
          // Justo encima de su plataforma.
          _Layer(
            tile.sprite.depth + 0.1,
            Positioned(
              left: tile.anchor.dx - markSize / 2,
              top: tile.anchor.dy - markSize / 2,
              width: markSize,
              height: markSize,
              child: Image.asset(
                mark,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    ];
    layers.sort((a, b) => a.depth.compareTo(b.depth));
    return layers;
  }

  String? _markOf(MapTile tile) {
    if (tile.id >= board.tiles.length) return null;
    return MapAssets.markFor(board.tile(tile.id).type);
  }
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
      child: sprite.flipX
          ? Transform.flip(flipX: true, child: image)
          : image,
    );
  }
}
