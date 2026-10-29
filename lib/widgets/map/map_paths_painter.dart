import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Pinta el caminito de piedra entre cada casilla y las siguientes, con la
/// textura repetida. En las bifurcaciones salen dos caminos solos.
///
/// Los extremos quedan debajo de las plataformas, que se dibujan encima.
class MapPathsPainter extends CustomPainter {
  MapPathsPainter({
    required this.map,
    required this.board,
    required this.texture,
  });

  final BoardMap map;
  final BoardLayout board;
  final ui.Image texture;

  /// Cerca de la mitad del ancho de una plataforma.
  static const pathWidth = 160.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ImageShader(
        texture,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidth
      ..strokeCap = StrokeCap.round;

    for (final tile in board.tiles) {
      final from = map.tiles[tile.id]?.anchor;
      if (from == null) continue;
      for (final nextId in tile.next) {
        final to = map.tiles[nextId]?.anchor;
        if (to != null) canvas.drawLine(from, to, paint);
      }
    }
  }

  @override
  bool shouldRepaint(MapPathsPainter oldDelegate) =>
      oldDelegate.map != map ||
      oldDelegate.board != board ||
      oldDelegate.texture != texture;
}
