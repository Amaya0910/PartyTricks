import 'package:flutter/material.dart';
import 'package:party_tricks/models/accessory_style.dart';
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
    this.accessory,
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

  /// Null = sin accesorio.
  final AccessoryStyle? accessory;

  /// La foto de la cara, si el jugador la usa. Solo se dibuja de frente.
  final FacePhoto? facePhoto;

  CharacterLook copyWith({
    Color? skinTone,
    EyeStyle? eyes,
    MouthStyle? mouth,
    ShirtStyle? shirt,
    AccessoryStyle? accessory,
    bool clearAccessory = false,
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
      accessory: clearAccessory ? null : accessory ?? this.accessory,
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
      other.accessory == accessory &&
      other.facePhoto == facePhoto;

  @override
  int get hashCode => Object.hash(
    skinTone,
    eyes,
    eyeColor,
    mouth,
    mouthColor,
    shirt,
    accessory,
    facePhoto,
  );
}
