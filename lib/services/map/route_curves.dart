import 'dart:math' as math;
import 'dart:ui';

import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';

/// Un tramo del camino entre dos casillas: una curva suave (Bézier cúbica)
/// en lugar de una recta.
///
/// [pointAt] reparte el avance por **distancia**, no por el parámetro de la
/// curva: así el personaje camina a paso parejo aunque la curva se cierre.
class RouteCurve {
  RouteCurve(this.start, this.control1, this.control2, this.end) {
    var previous = start;
    var total = 0.0;
    _lengths.add(0);
    for (var i = 1; i <= _samples; i++) {
      final point = _bezier(i / _samples);
      total += (point - previous).distance;
      _lengths.add(total);
      previous = point;
    }
  }

  /// Un tramo recto de [start] a [end].
  factory RouteCurve.straight(Offset start, Offset end) => RouteCurve(
    start,
    Offset.lerp(start, end, 1 / 3)!,
    Offset.lerp(start, end, 2 / 3)!,
    end,
  );

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  static const _samples = 32;
  final List<double> _lengths = [];

  /// Largo aproximado del tramo.
  double get length => _lengths.last;

  Offset _bezier(double t) {
    final u = 1 - t;
    return start * (u * u * u) +
        control1 * (3 * u * u * t) +
        control2 * (3 * u * t * t) +
        end * (t * t * t);
  }

  /// El punto cuando se ha recorrido la fracción [t] (0 a 1) del tramo.
  Offset pointAt(double t) {
    final clamped = t.clamp(0.0, 1.0);
    if (length == 0) return start;
    final target = clamped * length;
    var low = 0;
    var high = _samples;
    while (high - low > 1) {
      final mid = (low + high) ~/ 2;
      if (_lengths[mid] <= target) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final span = _lengths[high] - _lengths[low];
    final local = span == 0 ? 0.0 : (target - _lengths[low]) / span;
    return _bezier((low + local) / _samples);
  }

  /// Hacia dónde va la curva al salir de [start], con largo 1.
  Offset get startDirection => _unit(control1 - start, end - start);

  /// Hacia dónde va la curva al llegar a [end], con largo 1.
  Offset get endDirection => _unit(end - control2, end - start);

  /// El tramo como trazo, para pintarlo.
  Path get path => Path()
    ..moveTo(start.dx, start.dy)
    ..cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );

  static Offset _unit(Offset v, Offset fallback) {
    final d = v.distance;
    if (d > 1e-6) return v / d;
    final f = fallback.distance;
    return f > 1e-6 ? fallback / f : const Offset(1, 0);
  }
}

/// Los caminos suaves de todo el tablero.
///
/// Cada tramo sale de una casilla y llega a la siguiente **sin quiebres**: en
/// cada casilla, la curva que llega y la que sale comparten la misma
/// dirección (la mitad entre las dos rectas). En una bifurcación, cada
/// desvío sale con su propia curva. Tanto el dibujo del camino como la
/// caminata del personaje usan estos mismos tramos.
class RouteCurves {
  RouteCurves._(this._curves);

  /// Calcula las curvas de [board] con las casillas de [map]. Lo que el mapa
  /// no tenga dibujado se salta.
  factory RouteCurves.build(
    BoardMap map,
    BoardLayout board, {
    double handle = 0.38,
  }) {
    Offset? anchor(int id) => map.tiles[id]?.anchor;

    // Quiénes llegan a cada casilla.
    final incoming = <int, List<int>>{};
    for (final tile in board.tiles) {
      for (final next in tile.next) {
        incoming.putIfAbsent(next, () => []).add(tile.id);
      }
    }

    Offset unit(Offset v) {
      final d = v.distance;
      return d < 1e-6 ? Offset.zero : v / d;
    }

    final curves = <(int, int), RouteCurve>{};
    for (final tile in board.tiles) {
      final a = anchor(tile.id);
      if (a == null) continue;
      for (final nextId in tile.next) {
        final b = anchor(nextId);
        if (b == null) continue;
        final chord = unit(b - a);
        if (chord == Offset.zero) {
          curves[(tile.id, nextId)] = RouteCurve.straight(a, b);
          continue;
        }
        // Al salir: el promedio entre lo que llega a esta casilla y este tramo.
        var leaving = chord;
        for (final p in incoming[tile.id] ?? const <int>[]) {
          final pa = anchor(p);
          if (pa != null) leaving += unit(a - pa);
        }
        // Al llegar: el promedio entre este tramo y lo que sale de la otra.
        var arriving = chord;
        for (final n in board.tile(nextId).next) {
          final na = anchor(n);
          if (na != null) arriving += unit(na - b);
        }
        leaving = unit(leaving) == Offset.zero ? chord : unit(leaving);
        arriving = unit(arriving) == Offset.zero ? chord : unit(arriving);
        final reach = (b - a).distance * handle;
        curves[(tile.id, nextId)] = RouteCurve(
          a,
          a + leaving * reach,
          b - arriving * reach,
          b,
        );
      }
    }
    return RouteCurves._(curves);
  }

  final Map<(int, int), RouteCurve> _curves;

  /// Todos los tramos, para pintarlos.
  Iterable<RouteCurve> get all => _curves.values;

  /// El tramo de [from] a [to]. Si no están conectadas (un salto directo),
  /// una recta entre sus puntos [fallbackFrom] y [fallbackTo].
  RouteCurve curve(
    int from,
    int to, {
    required Offset fallbackFrom,
    required Offset fallbackTo,
  }) => _curves[(from, to)] ?? RouteCurve.straight(fallbackFrom, fallbackTo);

  /// Cuánto se aparta el tramo de la recta (para las pruebas): la mayor
  /// distancia entre la curva y su cuerda.
  static double bulge(RouteCurve curve) {
    final chord = curve.end - curve.start;
    final len = chord.distance;
    if (len == 0) return 0;
    var worst = 0.0;
    for (var i = 1; i < 10; i++) {
      final p = curve.pointAt(i / 10) - curve.start;
      final off = (p.dx * chord.dy - p.dy * chord.dx).abs() / len;
      worst = math.max(worst, off);
    }
    return worst;
  }
}
