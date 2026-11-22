import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/character_view.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/character_head.dart';
import 'package:party_tricks/widgets/character/character_layer.dart';

export 'package:party_tricks/widgets/character/character_layer.dart'
    show kCharacterCanvas, kCharacterTopMargin;

/// Partes del cuerpo, en orden de dibujo (de atrás hacia adelante).
///
/// Cada parte tiene dos PNG del mismo tamaño que el lienzo:
///   `assets/images/personaje/frente/cuerpo/relleno_<id>.png` (blanco, se tiñe)
///   `assets/images/personaje/frente/cuerpo/linea_<id>.png`   (negro, no se tiñe)
/// La cabeza es la misma de frente y de lado: está en `personaje/`.
enum BodyPart {
  cuerpo('cuerpo', Offset(256, 555 + kCharacterTopMargin)),
  piernaIzquierda('pierna_izquierda', Offset(228, 511 + kCharacterTopMargin)),
  piernaDerecha('pierna_derecha', Offset(284, 511 + kCharacterTopMargin)),
  brazoIzquierdo('brazo_izquierdo', Offset(222, 392 + kCharacterTopMargin)),
  brazoDerecho('brazo_derecha', Offset(290, 392 + kCharacterTopMargin)),
  manoIzquierda(
    'mano_izquierda',
    Offset(222, 392 + kCharacterTopMargin),
  ), // gira con el brazo
  manoDerecha('mano_derecha', Offset(290, 392 + kCharacterTopMargin)),
  cabeza('cabeza', Offset(256, 360 + kCharacterTopMargin));

  const BodyPart(this.id, this.pivot);

  final String id;

  /// Punto (en píxeles del lienzo) alrededor del cual gira o escala.
  final Offset pivot;

  String get _folder => this == cabeza
      ? 'assets/images/personaje'
      : 'assets/images/personaje/frente/cuerpo';

  String get fillAsset => '$_folder/relleno_$id.png';
  String get outlineAsset => '$_folder/linea_$id.png';
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

/// Caminar de espalda (hacia arriba en el mapa): las piernas se levantan una
/// y luego la otra, el cuerpo sube y baja con cada paso y los brazos se
/// mecen al revés de las piernas. La fase 0 a 1 son dos pasos.
class WalkAwayAnimation implements CharacterAnimation {
  const WalkAwayAnimation();

  static const double _deg = math.pi / 180;

  @override
  Duration get period => const Duration(milliseconds: 700);

  @override
  PartTransform transformFor(BodyPart part, double t) {
    final phase = t * 2 * math.pi;
    final swing = math.sin(phase);
    // El cuerpo está más abajo cuando las dos piernas tocan el piso.
    final bob = -5 * (1 - swing.abs());
    switch (part) {
      case BodyPart.cuerpo:
        return PartTransform(dy: bob);
      case BodyPart.cabeza:
        return PartTransform(
          angle: math.sin(phase * 2) * 1.5 * _deg,
          dy: bob * 1.1,
        );
      case BodyPart.piernaIzquierda:
        final lift = math.max(0.0, swing);
        return PartTransform(dy: -16 * lift, scaleY: 1 - 0.12 * lift);
      case BodyPart.piernaDerecha:
        final lift = math.max(0.0, -swing);
        return PartTransform(dy: -16 * lift, scaleY: 1 - 0.12 * lift);
      case BodyPart.brazoIzquierdo:
      case BodyPart.manoIzquierda:
        return PartTransform(
          angle: 2.5 * _deg * swing,
          dy: bob - 5 * swing,
          scaleY: 1 - 0.05 * swing,
        );
      case BodyPart.brazoDerecho:
      case BodyPart.manoDerecha:
        return PartTransform(
          angle: -2.5 * _deg * swing,
          dy: bob + 5 * swing,
          scaleY: 1 + 0.05 * swing,
        );
    }
  }
}

/// Personaje animado por capas con tono de piel, ojos y boca configurables.
class AnimatedCharacter extends StatefulWidget {
  const AnimatedCharacter({
    super.key,
    required this.skinTone,
    this.animation = const IdleAnimation(),
    this.phase,
    this.eyes = EyeStyle.defaultStyle,
    this.eyeColor = AppColors.white,
    this.mouth = MouthStyle.defaultStyle,
    this.mouthColor,
    this.shirt = ShirtStyle.defaultStyle,
    this.pants,
    this.accessory,
    this.hair,
    this.hairTint,
    this.facePhoto,
    this.clothing = const [],
    this.view = CharacterView.frente,
  });

  /// El personaje con el aspecto [look]. La foto de la cara es la de [look].
  AnimatedCharacter.fromLook(
    CharacterLook look, {
    Key? key,
    CharacterAnimation animation = const IdleAnimation(),
    Animation<double>? phase,
    CharacterView view = CharacterView.frente,
  }) : this(
         view: view,
         key: key,
         skinTone: look.skinTone,
         animation: animation,
         phase: phase,
         eyes: look.eyes,
         eyeColor: look.eyeColor,
         mouth: look.mouth,
         mouthColor: look.mouthColor,
         shirt: look.shirt,
         pants: look.pants,
         accessory: look.accessory,
         hair: look.hair,
         hairTint: look.hairTint,
         facePhoto: look.facePhoto,
       );

  /// Desde dónde se ve: de frente (con cara) o de espalda. De lado es
  /// `WalkingCharacter`.
  final CharacterView view;

  final Color skinTone;
  final CharacterAnimation animation;

  /// Fase (0 a 1) de la animación, si quien lo usa la lleva él (la vista
  /// previa de administración). Si es null, el personaje se mueve solo en
  /// bucle. No se puede cambiar después de crearlo.
  final Animation<double>? phase;

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

  /// Camisa puesta: el cuerpo la lleva y las mangas giran con los brazos.
  final ShirtStyle shirt;

  /// Pantalón puesto, si lleva (solo de frente). Va sobre las piernas, sin
  /// moverse: en el reposo las piernas están quietas.
  final PantsStyle? pants;

  /// Accesorio de la cabeza, si lleva. Se mueve con ella.
  final AccessoryStyle? accessory;

  /// Cabello, si lleva, y su color (null si trae el suyo).
  final HairStyle? hair;
  final Color? hairTint;

  /// Foto de la cara del jugador. Si hay, se dibuja en lugar de los ojos y
  /// la boca.
  final FacePhoto? facePhoto;

  /// Capas de ropa/cara (mismo lienzo 512x968), se dibujan encima.
  final List<String> clothing;

  @override
  State<AnimatedCharacter> createState() => _AnimatedCharacterState();
}

class _AnimatedCharacterState extends State<AnimatedCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController? _own = widget.phase == null
      ? (AnimationController(vsync: this, duration: widget.animation.period)
          ..repeat())
      : null;

  Animation<double> get _phase => widget.phase ?? _own!;

  @override
  void dispose() {
    _own?.dispose();
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
        (
          part: part,
          layers: part == BodyPart.cabeza
              ? CharacterHead(
                  skinTone: widget.skinTone,
                  eyes: widget.eyes,
                  eyeColor: widget.eyeColor,
                  mouth: widget.mouth,
                  mouthColor: widget.mouthColor ?? widget.skinTone,
                  photo: widget.facePhoto,
                  accessory: widget.accessory,
                  view: widget.view,
                  hair: widget.hair,
                  hairTint: widget.hairTint,
                  includeBackHair: false,
                )
              : _PartLayers(
                  part: part,
                  skinTone: widget.skinTone,
                  shirt: widget.shirt,
                  view: widget.view,
                ),
        ),
    ];
    // La parte de atrás del cabello es la capa más atrás de todas: debajo del
    // cuerpo, para que no se vea delante del cuello. Se mueve con la cabeza.
    final backHairAsset = widget.hair?.backAssetFor(widget.view);
    final backHair = backHairAsset == null
        ? null
        : CharacterLayer(backHairAsset, tint: widget.hairTint);
    final pantsAsset = widget.pants?.assetFor(widget.view);
    final pantsLayer = pantsAsset == null ? null : CharacterLayer(pantsAsset);
    final clothing = [
      for (final asset in widget.clothing) CharacterLayer(asset),
    ];

    // Aísla la animación: el resto de la pantalla no se repinta con ella.
    return RepaintBoundary(
      child: FittedBox(
        child: SizedBox.fromSize(
          size: kCharacterCanvas,
          child: AnimatedBuilder(
            animation: _phase,
            builder: (context, _) {
              final t = _phase.value;
              return Stack(
                children: [
                  if (backHair != null)
                    Transform(
                      transform: _matrixOf(
                        BodyPart.cabeza,
                        widget.animation.transformFor(BodyPart.cabeza, t),
                      ),
                      child: backHair,
                    ),
                  for (final p in parts) ...[
                    Transform(
                      transform: _matrixOf(
                        p.part,
                        widget.animation.transformFor(p.part, t),
                      ),
                      child: p.layers,
                    ),
                    // El pantalón va sobre las dos piernas y debajo de los brazos.
                    if (p.part == BodyPart.piernaDerecha && pantsLayer != null)
                      pantsLayer,
                  ],
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

/// Las capas de una parte del cuerpo (menos la cabeza), sin mover.
class _PartLayers extends StatelessWidget {
  const _PartLayers({
    required this.part,
    required this.skinTone,
    required this.shirt,
    required this.view,
  });

  /// De frente o de espalda (cambia el dibujo de la camisa).
  final CharacterView view;

  final BodyPart part;
  final Color skinTone;
  final ShirtStyle shirt;

  /// Lo de la camisa que va con esta parte: la camisa en el cuerpo y cada
  /// manga en su brazo (gira con él y queda debajo de la mano).
  String? get _shirtAsset => switch (part) {
    BodyPart.cuerpo => shirt.bodyAsset(view),
    BodyPart.brazoIzquierdo => shirt.frontSleeve(left: true),
    BodyPart.brazoDerecho => shirt.frontSleeve(left: false),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CharacterLayer(part.fillAsset, tint: skinTone),
        CharacterLayer(part.outlineAsset),
        if (_shirtAsset case final asset?)
          CharacterLayer(asset, tint: shirt.tint),
      ],
    );
  }
}
