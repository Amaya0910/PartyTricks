import 'package:flutter/rendering.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/map_theme.dart';

/// Pinta el camino entre cada casilla y las siguientes, con la textura del
/// tema repetida (o de su color, si no hay textura). En las bifurcaciones
/// salen dos caminos solos.
///
/// Los extremos quedan debajo de las plataformas, que se dibujan encima.
class MapPathsPainter extends CustomPainter {
  MapPathsPainter({
    required this.map,
    required this.board,
    required this.theme,
  });

  final BoardMap map;
  final BoardLayout board;
  final LoadedMapTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final texture = theme.pathTexture;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.theme.pathWidth
      ..strokeCap = StrokeCap.round;
    if (texture != null) {
      paint.shader = ImageShader(
        texture,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
    } else {
      paint.color = theme.colors.path;
    }

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
      oldDelegate.theme != theme;
}
