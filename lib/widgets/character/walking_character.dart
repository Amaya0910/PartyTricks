import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/widgets/character/character_head.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';

/// Cómo está el cuerpo en un instante de la caminata. Los ángulos van en
/// radianes y se miran con el personaje de frente a la derecha: negativo =
/// hacia adelante, positivo = hacia atrás. "Cerca" es la pierna o el brazo
/// que da hacia el lado de la cámara; "lejos", el de atrás.
@immutable
class WalkPose {
  const WalkPose({
    required this.nearThigh,
    required this.nearKnee,
    required this.farThigh,
    required this.farKnee,
    required this.nearArm,
    required this.farArm,
    required this.bodyDy,
    required this.headAngle,
  });

  final double nearThigh;

  /// Cuánto se dobla la rodilla (siempre >= 0: la pantorrilla va hacia atrás).
  final double nearKnee;
  final double farThigh;
  final double farKnee;

  /// El brazo (con su mano) y el muslo de cada lado van al revés: si la pierna
  /// cercana va adelante, el brazo cercano va atrás.
  final double nearArm;
  final double farArm;

  /// Cuánto baja el cuerpo, en píxeles del lienzo, para que el pie que
  /// está apoyado siga tocando el piso cuando la pierna se abre.
  final double bodyDy;

  /// Cuánto se inclina la cabeza.
  final double headAngle;
}

/// El ciclo de caminata: dos pasos (uno con cada pierna) por vuelta.
///
/// [poseAt] recibe la fase de 0 a 1 y devuelve la misma pose en 0 y en 1, así
/// que se puede repetir sin saltos.
class WalkCycle {
  const WalkCycle({
    this.stride = 0.5,
    this.kneeBend = 0.7,
    this.armSwing = 0.55,
    this.legLength = 180,
  });

  /// Cuánto abre cada muslo hacia adelante y hacia atrás.
  final double stride;

  /// Cuánto se dobla la rodilla al levantar el pie.
  final double kneeBend;

  /// Cuánto se mueve cada brazo.
  final double armSwing;

  /// De la cadera al pie, en píxeles del lienzo.
  final double legLength;

  WalkPose poseAt(double t) {
    final phase = 2 * math.pi * t;
    final swing = math.sin(phase);
    // La pierna cercana pasa hacia adelante cuando cos(phase) > 0; ahí se
    // dobla la rodilla para no arrastrar el pie. La lejana va medio ciclo
    // después.
    double knee(double p) => kneeBend * math.max(0.0, math.cos(p));
    return WalkPose(
      nearThigh: -stride * swing,
      nearKnee: knee(phase),
      farThigh: stride * swing,
      farKnee: knee(phase + math.pi),
      nearArm: armSwing * swing,
      farArm: -armSwing * swing,
      bodyDy: legLength * (1 - math.cos(stride * swing.abs())),
      headAngle: 0.03 * math.sin(phase * 2),
    );
  }
}

/// El personaje caminando, visto de lado (carpeta `lado/`). Mira a la
/// derecha; con [faceRight] en false se voltea.
///
/// Lleva la camisa y el accesorio del jugador (la manga gira con el brazo).
///
/// Cada pierna y cada brazo se dibuja dos veces: una pareja delante del cuerpo
/// y otra detrás (un poco más oscura), y se mueven en sentidos contrarios, de
/// modo que se ven dos piernas y dos brazos. El muslo gira desde la cadera, la
/// rodilla desde su articulación y el brazo (con la mano) desde el hombro.
///
/// [phase] (0 a 1) es la fase del ciclo: una vuelta completa son dos pasos.
/// Quien lo usa la avanza mientras el personaje se mueve.
class WalkingCharacter extends StatelessWidget {
  const WalkingCharacter({
    super.key,
    required this.phase,
    required this.look,
    this.faceRight = true,
    this.cycle = const WalkCycle(),
  });

  final Animation<double> phase;
  final CharacterLook look;
  final bool faceRight;
  final WalkCycle cycle;

  static const String _folder = 'assets/images/personaje/lado/cuerpo';

  // Articulaciones, en píxeles del lienzo de 512 x 768.
  static const Offset shoulder = Offset(256, 425);
  static const Offset hip = Offset(256, 535);
  static const Offset knee = Offset(256, 612);

  /// Los pies del dibujo de lado llegan más abajo (714) que los de frente
  /// (697); se sube para que al pasar de uno a otro no se muevan.
  static const double _feetOffset = 714 - 697;

  /// Gira [angle] alrededor de [pivot] (y baja [dy]).
  static Matrix4 _around(Offset pivot, double angle, [double dy = 0]) {
    return Matrix4.identity()
      ..translateByDouble(pivot.dx, pivot.dy + dy, 0, 1)
      ..rotateZ(angle)
      ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
  }

  /// Una pieza con su relleno (que toma el color) y su línea.
  static Widget _piece(String name, Color tone) => Stack(
    children: [
      CharacterLayer('$_folder/${name}_relleno.png', tint: tone),
      CharacterLayer('$_folder/${name}_linea.png'),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final skin = look.skinTone;
    // Lo que queda atrás se ve un poco más oscuro, para dar profundidad.
    final back = Color.lerp(skin, Colors.black, 0.14)!;
    final shirt = look.shirt;
    final shirtTint = shirt.tint;
    final backShirtTint = Color.lerp(
      shirtTint ?? Colors.white,
      Colors.black,
      0.14,
    )!;

    // Las capas no cambian de un cuadro a otro: se arman una vez y en cada
    // cuadro solo se recalcula cómo gira cada una.
    final torso = _piece('torso', skin);
    final shirtLayer = CharacterLayer(
      shirt.bodyAsset(CharacterView.lado, faceRight: faceRight),
      tint: shirtTint,
    );
    final head = CharacterHead(
      skinTone: skin,
      eyes: look.eyes,
      eyeColor: look.eyeColor,
      mouth: look.mouth,
      mouthColor: look.mouthColor ?? skin,
      accessory: look.accessory,
      view: CharacterView.lado,
    );
    final nearThigh = _piece('muslo', skin);
    final nearShin = _piece('rodilla', skin);
    final farThigh = _piece('muslo', back);
    final farShin = _piece('rodilla', back);
    // La manga queda sobre el brazo y debajo de la mano.
    final sleeve = shirt.sideSleeve;
    final nearArm = [
      _piece('brazo', skin),
      if (sleeve != null) CharacterLayer(sleeve, tint: shirtTint),
      _piece('mano', skin),
    ];
    final farArm = [
      _piece('brazo', back),
      if (sleeve != null) CharacterLayer(sleeve, tint: backShirtTint),
      _piece('mano', back),
    ];

    // El arte mira a la derecha: yendo a la izquierda se voltea pieza por
    // pieza. Así la camisa que se ve distinto de cada lado puede quedar sin
    // voltear, con su propio dibujo para la izquierda.
    Widget mirror(Widget child) => faceRight
        ? child
        : Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1, 1, 1),
            child: child,
          );

    Widget leg(Widget thigh, Widget shin, double thighAngle, double kneeAngle) {
      return Transform(
        transform: _around(hip, thighAngle),
        child: Stack(
          children: [
            thigh,
            // La pantorrilla gira con el muslo y, además, desde la rodilla.
            Transform(transform: _around(knee, kneeAngle), child: shin),
          ],
        ),
      );
    }

    Widget arm(List<Widget> pieces, double angle) {
      return Transform(
        transform: _around(shoulder, angle),
        child: Stack(children: pieces),
      );
    }

    return RepaintBoundary(
      child: FittedBox(
        child: SizedBox.fromSize(
          size: kCharacterCanvas,
          child: AnimatedBuilder(
            animation: phase,
            builder: (context, _) {
              final pose = cycle.poseAt(phase.value);
              return Transform.translate(
                offset: Offset(0, pose.bodyDy - _feetOffset),
                child: Stack(
                  children: [
                    mirror(arm(farArm, pose.farArm)),
                    mirror(leg(farThigh, farShin, pose.farThigh, pose.farKnee)),
                    mirror(torso),
                    shirt.sidedInProfile ? shirtLayer : mirror(shirtLayer),
                    mirror(
                      leg(nearThigh, nearShin, pose.nearThigh, pose.nearKnee),
                    ),
                    mirror(arm(nearArm, pose.nearArm)),
                    mirror(
                      Transform(
                        transform: _around(
                          const Offset(256, 340),
                          pose.headAngle,
                        ),
                        child: head,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
