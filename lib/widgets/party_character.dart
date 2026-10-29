import 'dart:math';

import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// El personaje de un jugador, provisional hasta tener las hojas de
/// animación (arte_imagenes.md, sección 7): cabeza grande, ojos de óvalo
/// negro, gorra y ropa con el color del jugador y contorno negro.
///
/// - Mide [height] de alto y 2/3 de eso de ancho, igual que los frames.
/// - Con [idle] respira: el cuerpo se estira un poco y la cabeza sube y baja.
///   [idlePhase] (0 a 1) desfasa la respiración para que no vayan todos
///   al mismo tiempo.
/// - Si hay [photoUrl], la foto va en la cara.
class PartyCharacter extends StatefulWidget {
  const PartyCharacter({
    super.key,
    required this.color,
    required this.height,
    this.photoUrl,
    this.idle = false,
    this.idlePhase = 0,
  });

  final Color color;
  final double height;
  final String? photoUrl;
  final bool idle;
  final double idlePhase;

  /// Ancho entre alto, como los frames de 256 × 384.
  static const aspectRatio = 2 / 3;

  @override
  State<PartyCharacter> createState() => _PartyCharacterState();
}

class _PartyCharacterState extends State<PartyCharacter>
    with SingleTickerProviderStateMixin {
  static const _breathDuration = Duration(milliseconds: 1400);

  AnimationController? _breath;

  @override
  void initState() {
    super.initState();
    _syncBreath();
  }

  @override
  void didUpdateWidget(PartyCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idle != widget.idle) _syncBreath();
  }

  @override
  void dispose() {
    _breath?.dispose();
    super.dispose();
  }

  void _syncBreath() {
    if (!widget.idle) {
      _breath?.dispose();
      _breath = null;
      return;
    }
    _breath ??= AnimationController(vsync: this, duration: _breathDuration)
      ..value = widget.idlePhase.clamp(0, 1).toDouble()
      ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final size = Size(
      widget.height * PartyCharacter.aspectRatio,
      widget.height,
    );
    final breath = _breath;
    if (breath == null) return _frame(size, 0);
    return AnimatedBuilder(
      animation: breath,
      builder: (context, _) =>
          _frame(size, Curves.easeInOut.transform(breath.value)),
    );
  }

  Widget _frame(Size size, double breath) {
    final head = _CharacterPainter.headRect(size, breath);
    final photoUrl = widget.photoUrl;
    return SizedBox.fromSize(
      size: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CharacterPainter(color: widget.color, breath: breath),
            ),
          ),
          if (photoUrl != null && photoUrl.isNotEmpty)
            Positioned.fromRect(
              rect: head.deflate(_CharacterPainter.strokeOf(size)),
              child: ClipOval(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  // Si la foto no carga, se ve la cara dibujada.
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dibuja el personaje dentro de su caja, con los pies abajo al centro.
class _CharacterPainter extends CustomPainter {
  _CharacterPainter({required this.color, required this.breath});

  final Color color;

  /// 0 = exhala, 1 = inhala.
  final double breath;

  static double strokeOf(Size size) => max(2, size.width * 0.03);

  /// Dónde va la cabeza: casi la mitad del alto, y sube un poco al inhalar.
  static Rect headRect(Size size, double breath) {
    final radius = size.width * 0.36;
    final center = Offset(
      size.width / 2,
      size.height * 0.30 - breath * size.height * 0.015,
    );
    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = Color.lerp(color, AppColors.characterOutline, 0.35)!;
    final outline = Paint()
      ..color = AppColors.characterOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeOf(size)
      ..strokeJoin = StrokeJoin.round;
    void shape(Path path, Color fill) {
      canvas
        ..drawPath(path, Paint()..color = fill)
        ..drawPath(path, outline);
    }

    // Sombra en el piso.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.965),
        width: w * 0.62,
        height: h * 0.05,
      ),
      Paint()..color = AppColors.characterShadow,
    );

    // Piernas.
    for (final x in [w * 0.40, w * 0.60]) {
      shape(
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(x - w * 0.075, h * 0.78, x + w * 0.075, h * 0.955),
            Radius.circular(w * 0.06),
          ),
        ),
        dark,
      );
    }

    // Brazos, detrás del cuerpo.
    final torsoTop = h * 0.52 - breath * h * 0.012;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(w / 2 + side * w * 0.27, h * 0.66);
      canvas.rotate(side * 0.35);
      shape(
        Path()..addOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: w * 0.16,
            height: h * 0.2,
          ),
        ),
        color,
      );
      canvas.drawCircle(
        Offset(0, h * 0.09),
        w * 0.06,
        Paint()..color = AppColors.characterSkin,
      );
      canvas.restore();
    }

    // Cuerpo: respira estirándose hacia arriba.
    shape(
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.25, torsoTop, w * 0.75, h * 0.83),
          Radius.circular(w * 0.18),
        ),
      ),
      color,
    );

    // Cabeza con gorra del color del jugador.
    final head = headRect(size, breath);
    final headPath = Path()..addOval(head);
    canvas.drawPath(headPath, Paint()..color = AppColors.characterSkin);
    canvas.save();
    canvas.clipPath(headPath);
    canvas.drawRect(
      Rect.fromLTRB(
        head.left,
        head.top,
        head.right,
        head.top + head.height * 0.36,
      ),
      Paint()..color = color,
    );
    canvas.restore();
    canvas.drawPath(headPath, outline);
    // Visera de la gorra.
    shape(
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            head.center.dx,
            head.top + head.height * 0.31,
            head.right + w * 0.08,
            head.top + head.height * 0.40,
          ),
          Radius.circular(w * 0.04),
        ),
      ),
      dark,
    );

    // Cara: ojos de óvalo negro, mejillas y una sonrisa pequeña.
    final eyeY = head.top + head.height * 0.56;
    for (final side in [-1.0, 1.0]) {
      final x = head.center.dx + side * head.width * 0.15;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, eyeY),
          width: head.width * 0.10,
          height: head.height * 0.17,
        ),
        Paint()..color = AppColors.characterOutline,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            x + side * head.width * 0.07,
            eyeY + head.height * 0.14,
          ),
          width: head.width * 0.13,
          height: head.height * 0.07,
        ),
        Paint()..color = AppColors.characterBlush,
      );
    }
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(head.center.dx, eyeY + head.height * 0.12),
        width: head.width * 0.14,
        height: head.height * 0.10,
      ),
      0.2,
      pi - 0.4,
      false,
      outline..strokeWidth = strokeOf(size) * 0.8,
    );
  }

  @override
  bool shouldRepaint(_CharacterPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.breath != breath;
}
