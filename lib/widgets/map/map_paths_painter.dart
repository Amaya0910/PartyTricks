import 'package:flutter/rendering.dart';
import 'package:party_tricks/services/map/map_theme.dart';
import 'package:party_tricks/services/map/route_curves.dart';

/// Pinta el camino entre cada casilla y las siguientes, en curvas suaves (no
/// rectas), con la textura del tema repetida (o de su color, si no hay
/// textura). En las bifurcaciones salen dos caminos solos.
///
/// Los extremos quedan debajo de las plataformas, que se dibujan encima.
class MapPathsPainter extends CustomPainter {
  MapPathsPainter({required this.routes, required this.theme});

  /// Los tramos suaves entre casillas (los mismos que recorre el personaje).
  final RouteCurves routes;
  final LoadedMapTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final texture = theme.pathTexture;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.theme.pathWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
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

    for (final curve in routes.all) {
      canvas.drawPath(curve.path, paint);
    }
  }

  @override
  bool shouldRepaint(MapPathsPainter oldDelegate) =>
      oldDelegate.routes != routes || oldDelegate.theme != theme;
}
