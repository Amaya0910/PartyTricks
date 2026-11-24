import 'dart:math';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/widgets/map/offscreen_marker.dart';

void main() {
  const phone = Size(400, 700);
  const size = 44.0;
  const margin = 12.0;

  OffscreenMarker? place(Offset target, [Size viewport = phone]) =>
      placeOffscreenMarker(
        target: target,
        viewport: viewport,
        size: size,
        margin: margin,
      );

  /// El indicador entero queda dentro de la pantalla, sin tocar el margen.
  void expectInside(OffscreenMarker marker, [Size viewport = phone]) {
    final box = Rect.fromCenter(
      center: marker.center,
      width: size,
      height: size,
    );
    final allowed = (Offset.zero & viewport).deflate(margin - 0.001);
    expect(allowed.contains(box.topLeft), isTrue, reason: '$box');
    expect(allowed.contains(box.bottomRight), isTrue, reason: '$box');
  }

  test('si el diamante se ve, no hay indicador', () {
    expect(place(const Offset(200, 350)), isNull);
    expect(place(const Offset(1, 1)), isNull);
    expect(place(const Offset(399, 699)), isNull);
  });

  test('a la derecha: pegado al borde derecho y apuntando a la derecha', () {
    final marker = place(const Offset(5000, 350))!;

    expect(marker.center.dx, phone.width - margin - size / 2);
    expect(marker.center.dy, closeTo(350, 0.001));
    expect(marker.angle, closeTo(0, 0.001));
    expectInside(marker);
  });

  test('arriba, abajo y a la izquierda', () {
    final up = place(const Offset(200, -900))!;
    expect(up.center.dx, closeTo(200, 0.001));
    expect(up.center.dy, closeTo(margin + size / 2, 0.001));
    expect(up.angle, closeTo(-pi / 2, 0.001));

    final down = place(const Offset(200, 9000))!;
    expect(down.center.dy, phone.height - margin - size / 2);
    expect(down.angle, closeTo(pi / 2, 0.001));

    final left = place(const Offset(-50, 350))!;
    expect(left.center.dx, margin + size / 2);
    expect(left.angle.abs(), closeTo(pi, 0.001));

    for (final marker in [up, down, left]) {
      expectInside(marker);
    }
  });

  test('en diagonal sale por el primer borde que cruza la línea', () {
    // Pantalla alta: hacia abajo a la derecha, primero se topa con el lado
    // derecho.
    final marker = place(const Offset(1400, 1350))!;

    expect(marker.center.dx, closeTo(phone.width - margin - size / 2, 0.001));
    expect(marker.center.dy, greaterThan(350));
    expect(marker.angle, closeTo(atan2(1000, 1200), 0.001));
    expectInside(marker);
  });

  test('lejos o cerca en la misma dirección, el indicador no se mueve', () {
    final near = place(const Offset(450, 350 + 50))!;
    final far = place(const Offset(200 + 25000, 350 + 5000))!;

    expect(near.center.dx, closeTo(far.center.dx, 0.001));
    expect(near.center.dy, closeTo(far.center.dy, 0.001));
    expect(near.angle, closeTo(far.angle, 0.001));
  });

  test('funciona acostado, en tablet y en cualquier dirección', () {
    for (final viewport in const [
      Size(700, 400),
      Size(1024, 1366),
      Size(320, 480),
    ]) {
      for (var degrees = 0; degrees < 360; degrees += 15) {
        final a = degrees * pi / 180;
        final target =
            viewport.center(Offset.zero) + Offset(cos(a), sin(a)) * 50000;
        final marker = place(target, viewport)!;
        expectInside(marker, viewport);
        expect(
          cos(marker.angle - a),
          closeTo(1, 0.001),
          reason: '$viewport, $degrees°',
        );
      }
    }
  });

  test(
    'si la pantalla es demasiado chica para el indicador, no se muestra',
    () {
      expect(place(const Offset(500, 500), const Size(40, 40)), isNull);
      expect(place(const Offset(500, 500), Size.zero), isNull);
    },
  );
}
