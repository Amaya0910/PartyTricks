import 'dart:math';
import 'dart:ui' show Offset, Rect, Size;

/// Dónde va un indicador en el borde de la pantalla y hacia dónde apunta.
class OffscreenMarker {
  const OffscreenMarker({required this.center, required this.angle});

  /// Centro del indicador, en coordenadas de la pantalla.
  final Offset center;

  /// Hacia dónde apunta, en radianes (0 = derecha, como `atan2`).
  final double angle;
}

/// El indicador para [target] (un punto en la pantalla), o null si se ve.
///
/// Va sobre la línea que une el centro de [viewport] con [target], pegado
/// al borde: queda a [margin] del borde y entero adentro aunque mida [size].
/// Null también si la pantalla es tan chica que no cabe.
OffscreenMarker? placeOffscreenMarker({
  required Offset target,
  required Size viewport,
  required double size,
  double margin = 12,
}) {
  final screen = Offset.zero & viewport;
  if (screen.isEmpty || screen.contains(target)) return null;
  final inset = margin + size / 2;
  final area = Rect.fromLTRB(
    inset,
    inset,
    viewport.width - inset,
    viewport.height - inset,
  );
  if (area.width <= 0 || area.height <= 0) return null;

  final from = area.center;
  final direction = target - from;
  // Hasta dónde llega la línea antes de salir de [area] por cada eje.
  final toX = direction.dx == 0
      ? double.infinity
      : ((direction.dx > 0 ? area.right : area.left) - from.dx) / direction.dx;
  final toY = direction.dy == 0
      ? double.infinity
      : ((direction.dy > 0 ? area.bottom : area.top) - from.dy) / direction.dy;
  return OffscreenMarker(
    center: from + direction * min(toX, toY),
    angle: atan2(direction.dy, direction.dx),
  );
}
