import 'package:flutter/material.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';

/// La forma de la cabeza del personaje, sacada de `relleno_cabeza.png`. Con
/// ella se recorta la foto de la cara para que cubra toda la cabeza, y se
/// dibuja la guía de la cámara y del editor.
abstract final class HeadShape {
  /// Cuadrado que rodea la cabeza, en píxeles del lienzo (512x968). La foto
  /// guardada llena este cuadrado.
  static const Rect zone = Rect.fromLTWH(
    92,
    46 + kCharacterTopMargin,
    328,
    328,
  );

  /// La misma zona con la altura original del lienzo, que es en la que están
  /// medidos los puntos de [_contour].
  static const Rect _drawnZone = Rect.fromLTWH(92, 46, 328, 328);

  /// Altura de los ojos y de la boca en la guía, de 0 (arriba) a 1 (abajo).
  static const double eyesLine = 0.48;
  static const double mouthLine = 0.74;

  /// Contorno de la cabeza en el lienzo, cada 3.75 grados.
  static const List<Offset> _contour = [
    Offset(415, 210),
    Offset(413, 220),
    Offset(411, 230),
    Offset(407, 240),
    Offset(403, 249),
    Offset(399, 259),
    Offset(395, 267),
    Offset(391, 276),
    Offset(385, 284),
    Offset(380, 293),
    Offset(374, 301),
    Offset(368, 308),
    Offset(361, 315),
    Offset(354, 322),
    Offset(347, 329),
    Offset(339, 335),
    Offset(331, 340),
    Offset(323, 346),
    Offset(314, 350),
    Offset(305, 355),
    Offset(296, 358),
    Offset(286, 361),
    Offset(276, 364),
    Offset(266, 365),
    Offset(256, 367),
    Offset(246, 366),
    Offset(236, 364),
    Offset(226, 362),
    Offset(216, 359),
    Offset(207, 355),
    Offset(197, 351),
    Offset(189, 346),
    Offset(181, 341),
    Offset(172, 336),
    Offset(165, 329),
    Offset(157, 323),
    Offset(150, 316),
    Offset(143, 309),
    Offset(137, 301),
    Offset(131, 293),
    Offset(126, 285),
    Offset(121, 277),
    Offset(116, 268),
    Offset(112, 259),
    Offset(108, 250),
    Offset(104, 240),
    Offset(100, 230),
    Offset(98, 220),
    Offset(96, 210),
    Offset(95, 199),
    Offset(95, 189),
    Offset(96, 178),
    Offset(98, 168),
    Offset(101, 157),
    Offset(105, 148),
    Offset(109, 137),
    Offset(114, 128),
    Offset(120, 119),
    Offset(127, 111),
    Offset(134, 103),
    Offset(142, 96),
    Offset(150, 89),
    Offset(159, 83),
    Offset(167, 77),
    Offset(176, 72),
    Offset(186, 68),
    Offset(196, 64),
    Offset(206, 61),
    Offset(215, 58),
    Offset(225, 56),
    Offset(236, 54),
    Offset(246, 53),
    Offset(256, 53),
    Offset(266, 53),
    Offset(276, 54),
    Offset(287, 56),
    Offset(297, 58),
    Offset(306, 61),
    Offset(316, 64),
    Offset(326, 68),
    Offset(335, 73),
    Offset(344, 78),
    Offset(353, 83),
    Offset(361, 90),
    Offset(370, 96),
    Offset(377, 104),
    Offset(385, 111),
    Offset(391, 120),
    Offset(397, 128),
    Offset(402, 138),
    Offset(407, 148),
    Offset(410, 158),
    Offset(413, 168),
    Offset(415, 178),
    Offset(416, 189),
    Offset(416, 200),
  ];

  /// La cabeza dibujada dentro de [target], que hace de [zone]. Las curvas
  /// pasan por los puntos medios del contorno, para que no se vean esquinas.
  static Path pathIn(Rect target) {
    Offset map(Offset point) => Offset(
      target.left +
          (point.dx - _drawnZone.left) / _drawnZone.width * target.width,
      target.top +
          (point.dy - _drawnZone.top) / _drawnZone.height * target.height,
    );

    final points = [for (final point in _contour) map(point)];
    Offset middle(Offset a, Offset b) => (a + b) / 2;

    final start = middle(points.last, points.first);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final end = middle(point, points[(i + 1) % points.length]);
      path.quadraticBezierTo(point.dx, point.dy, end.dx, end.dy);
    }
    return path..close();
  }
}

/// Recorta a su hijo con la forma de la cabeza.
class HeadClipper extends CustomClipper<Path> {
  const HeadClipper();

  @override
  Path getClip(Size size) => HeadShape.pathIn(Offset.zero & size);

  @override
  bool shouldReclip(HeadClipper oldClipper) => false;
}

/// La guía que se pone encima de la cámara y del editor: oscurece lo que
/// queda fuera de la cabeza y marca su contorno y dónde van los ojos y la
/// boca. [zone] es el cuadrado de la cabeza dentro del widget.
class HeadGuidePainter extends CustomPainter {
  const HeadGuidePainter({required this.zone, required this.scrim});

  final Rect zone;

  /// Color de lo que queda fuera de la cabeza.
  final Color scrim;

  @override
  void paint(Canvas canvas, Size size) {
    final head = HeadShape.pathIn(zone);
    // Par-impar: se pinta el rectángulo menos lo que cae dentro de la cabeza.
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addPath(head, Offset.zero),
      Paint()..color = scrim,
    );

    final lines = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2;
    for (final line in const [HeadShape.eyesLine, HeadShape.mouthLine]) {
      final y = zone.top + zone.height * line;
      final left = zone.left + zone.width * 0.24;
      final right = zone.right - zone.width * 0.24;
      for (var x = left; x < right; x += 14) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + 8).clamp(left, right), y),
          lines,
        );
      }
    }

    canvas.drawPath(
      head,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(HeadGuidePainter oldDelegate) =>
      oldDelegate.zone != zone || oldDelegate.scrim != scrim;
}
