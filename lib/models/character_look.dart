import 'package:flutter/material.dart';
import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/hair_color.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/pants_style.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/models/skin_tone.dart';

/// Cómo se ve un personaje: lo que se necesita para dibujarlo.
@immutable
class CharacterLook {
  const CharacterLook({
    required this.skinTone,
    this.eyes = EyeStyle.defaultStyle,
    required this.eyeColor,
    this.mouth = MouthStyle.defaultStyle,
    this.mouthColor,
    this.shirt = ShirtStyle.defaultStyle,
    this.pants,
    this.accessory,
    this.hair,
    this.hairColor = HairColor.defaultIndex,
    this.facePhoto,
  });

  /// El aspecto de quien todavía no ha elegido nada.
  static final CharacterLook standard = CharacterLook(
    skinTone: SkinTone.colorOf(SkinTone.defaultIndex),
    eyeColor: EyeColor.colorOf(EyeColor.defaultIndex),
    mouthColor: MouthColor.colorOf(MouthColor.defaultIndex),
  );

  final Color skinTone;
  final EyeStyle eyes;
  final Color eyeColor;
  final MouthStyle mouth;

  /// Null = sin color: la boca toma el tono de piel.
  final Color? mouthColor;
  final ShirtStyle shirt;

  /// Null = sin pantalón.
  final PantsStyle? pants;

  /// Null = sin accesorio.
  final AccessoryStyle? accessory;

  /// Null = sin cabello.
  final HairStyle? hair;

  /// Posición del color del cabello en [HairColor] (solo cuenta si el cabello
  /// es blanco).
  final int hairColor;

  /// El color que se le aplica al cabello: null si trae su propio color.
  Color? get hairTint =>
      hair != null && hair!.tintable ? HairColor.colorOf(hairColor) : null;

  /// La foto de la cara, si el jugador la usa. Solo se dibuja de frente.
  final FacePhoto? facePhoto;

  CharacterLook copyWith({
    Color? skinTone,
    EyeStyle? eyes,
    MouthStyle? mouth,
    ShirtStyle? shirt,
    PantsStyle? pants,
    bool clearPants = false,
    AccessoryStyle? accessory,
    bool clearAccessory = false,
    HairStyle? hair,
    bool clearHair = false,
    int? hairColor,
    FacePhoto? facePhoto,
    bool clearFacePhoto = false,
  }) {
    return CharacterLook(
      skinTone: skinTone ?? this.skinTone,
      eyes: eyes ?? this.eyes,
      eyeColor: eyeColor,
      mouth: mouth ?? this.mouth,
      mouthColor: mouthColor,
      shirt: shirt ?? this.shirt,
      pants: clearPants ? null : pants ?? this.pants,
      accessory: clearAccessory ? null : accessory ?? this.accessory,
      hair: clearHair ? null : hair ?? this.hair,
      hairColor: hairColor ?? this.hairColor,
      facePhoto: clearFacePhoto ? null : facePhoto ?? this.facePhoto,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CharacterLook &&
      other.skinTone == skinTone &&
      other.eyes == eyes &&
      other.eyeColor == eyeColor &&
      other.mouth == mouth &&
      other.mouthColor == mouthColor &&
      other.shirt == shirt &&
      other.pants == pants &&
      other.accessory == accessory &&
      other.hair == hair &&
      other.hairColor == hairColor &&
      other.facePhoto == facePhoto;

  @override
  int get hashCode => Object.hash(
    skinTone,
    eyes,
    eyeColor,
    mouth,
    mouthColor,
    shirt,
    pants,
    accessory,
    hair,
    hairColor,
    facePhoto,
  );
}
