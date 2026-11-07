import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/character_face.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';

export 'package:party_tricks/widgets/character/character_layer.dart'
    show kCharacterCanvas;

/// Partes del cuerpo, en orden de dibujo (de atrás hacia adelante).
///
/// Cada parte tiene dos PNG del mismo tamaño que el lienzo:
///   `assets/images/personaje/relleno_<id>.png`  (blanco, se tiñe)
///   `assets/images/personaje/linea_<id>.png`    (negro, no se tiñe)
enum BodyPart {
  cuerpo('cuerpo', Offset(256, 555)),
  piernaIzquierda('pierna_izquierda', Offset(228, 511)),
  piernaDerecha('pierna_derecha', Offset(284, 511)),
  brazoIzquierdo('brazo_izquierdo', Offset(222, 392)),
  brazoDerecho('brazo_derecha', Offset(290, 392)),
  manoIzquierda('mano_izquierda', Offset(222, 392)), // gira con el brazo
  manoDerecha('mano_derecha', Offset(290, 392)),
  cabeza('cabeza', Offset(256, 360));

  const BodyPart(this.id, this.pivot);

  final String id;

  /// Punto (en píxeles del lienzo) alrededor del cual gira o escala.
  final Offset pivot;

  String get fillAsset => 'assets/images/personaje/relleno_$id.png';
  String get outlineAsset => 'assets/images/personaje/linea_$id.png';
}

/// Transformación de una parte en un instante dado.
@immutable
class PartTransform {
  const PartTransform({this.angle = 0, this.dy = 0, this.scaleY = 1});

  static const identity = PartTransform();

  final double angle; // radianes
  final double dy; // píxeles del lienzo
  final double scaleY;
}

/// Define una animación: dada una fase t (0..1), cómo se mueve cada parte.
/// Para nuevas animaciones (saludar, celebrar...) se crea otra clase
/// que implemente esta interfaz, sin tocar el widget.
abstract interface class CharacterAnimation {
  Duration get period;
  PartTransform transformFor(BodyPart part, double t);
}

/// Idle: respiración (el torso se estira), cabeza y brazos suben un poco,
/// los brazos se abren levemente y la cabeza se balancea.
class IdleAnimation implements CharacterAnimation {
  const IdleAnimation();

  static const double _deg = math.pi / 180;

  @override
  Duration get period => const Duration(milliseconds: 2500);

  @override
  PartTransform transformFor(BodyPart part, double t) {
    final phase = t * 2 * math.pi;
    final breath = (1 - math.cos(phase)) / 2; // 0..1
    final lift = -5 * breath;

    switch (part) {
      case BodyPart.cuerpo:
        return PartTransform(scaleY: 1 + 0.022 * breath);
      case BodyPart.cabeza:
        return PartTransform(
          angle: math.sin(phase) * 1.2 * _deg,
          dy: lift * 1.1,
        );
      case BodyPart.brazoIzquierdo:
      case BodyPart.manoIzquierda:
        return PartTransform(angle: (1.5 + 1.5 * breath) * _deg, dy: lift);
      case BodyPart.brazoDerecho:
      case BodyPart.manoDerecha:
        return PartTransform(angle: -(1.5 + 1.5 * breath) * _deg, dy: lift);
      case BodyPart.piernaIzquierda:
      case BodyPart.piernaDerecha:
        return PartTransform.identity;
    }
  }
}

/// Personaje animado por capas con tono de piel, ojos y boca configurables.
class AnimatedCharacter extends StatefulWidget {
  const AnimatedCharacter({
    super.key,
    required this.skinTone,
    this.animation = const IdleAnimation(),
    this.eyes = EyeStyle.defaultStyle,
    this.eyeColor = AppColors.white,
    this.mouth = MouthStyle.defaultStyle,
    this.mouthColor,
    this.facePhoto,
    this.clothing = const [],
  });

  final Color skinTone;
  final CharacterAnimation animation;

  /// Ojos equipados. Van pegados a la cabeza: se mueven con ella.
  final EyeStyle eyes;

  /// Color que toma la parte blanca de la línea de los ojos (blanco =
  /// el dibujo original).
  final Color eyeColor;

  /// Boca equipada. Va pegada a la cabeza: se mueve con ella.
  final MouthStyle mouth;

  /// Color que toma la parte blanca de la boca. Null = sin color: toma el
  /// tono de piel.
  final Color? mouthColor;

  /// Foto de la cara del jugador. Si hay, se dibuja en lugar de los ojos y
  /// la boca.
  final FacePhoto? facePhoto;

  /// Capas de ropa/cara (mismo lienzo 512x768), se dibujan encima.
  final List<String> clothing;

  @override
  State<AnimatedCharacter> createState() => _AnimatedCharacterState();
}

class _AnimatedCharacterState extends State<AnimatedCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.animation.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Cómo queda [part] con [transform], alrededor de su pivote.
  Matrix4 _matrixOf(BodyPart part, PartTransform transform) {
    return Matrix4.identity()
      ..translateByDouble(part.pivot.dx, part.pivot.dy + transform.dy, 0, 1)
      ..rotateZ(transform.angle)
      ..scaleByDouble(1, transform.scaleY, 1, 1)
      ..translateByDouble(-part.pivot.dx, -part.pivot.dy, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    // Las capas no cambian de un cuadro a otro: se arman una vez y en cada
    // cuadro solo se recalcula dónde va cada parte.
    final parts = [
      for (final part in BodyPart.values)
        _PartLayers(
          part: part,
          skinTone: widget.skinTone,
          overlay: part == BodyPart.cabeza
              ? CharacterFace(
                  eyes: widget.eyes,
                  eyeColor: widget.eyeColor,
                  mouth: widget.mouth,
                  mouthColor: widget.mouthColor ?? widget.skinTone,
                  photo: widget.facePhoto,
                )
              : null,
        ),
    ];
    final clothing = [
      for (final asset in widget.clothing) CharacterLayer(asset),
    ];

    // Aísla la animación: el resto de la pantalla no se repinta con ella.
    return RepaintBoundary(
      child: FittedBox(
        child: SizedBox.fromSize(
          size: kCharacterCanvas,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                children: [
                  for (final layers in parts)
                    Transform(
                      transform: _matrixOf(
                        layers.part,
                        widget.animation.transformFor(layers.part, t),
                      ),
                      child: layers,
                    ),
                  ...clothing,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Las capas de una parte del cuerpo, sin mover.
class _PartLayers extends StatelessWidget {
  const _PartLayers({required this.part, required this.skinTone, this.overlay});

  final BodyPart part;
  final Color skinTone;

  /// Capa que se dibuja encima de la parte y se mueve con ella (los ojos
  /// y la boca en la cabeza).
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CharacterLayer(part.fillAsset, tint: skinTone),
        CharacterLayer(part.outlineAsset),
        ?overlay,
      ],
    );
  }
}
