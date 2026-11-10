import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:party_tricks/services/map/route_curves.dart';

/// Pinta el caminito de piedra entre cada casilla y las siguientes, en curvas
/// suaves (no rectas), con la textura repetida. En las bifurcaciones salen dos caminos solos.
///
/// Los extremos quedan debajo de las plataformas, que se dibujan encima.
class MapPathsPainter extends CustomPainter {
  MapPathsPainter({required this.routes, required this.texture});

  /// Los tramos suaves entre casillas (los mismos que recorre el personaje).
  final RouteCurves routes;
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
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final curve in routes.all) {
      canvas.drawPath(curve.path, paint);
    }
  }

  @override
  bool shouldRepaint(MapPathsPainter oldDelegate) =>
      oldDelegate.routes != routes || oldDelegate.texture != texture;
}
