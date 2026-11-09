import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/hair_color.dart';
import 'package:party_tricks/models/hair_style.dart';
import 'package:party_tricks/models/avatar_color.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/models/skin_tone.dart';

/// Datos del jugador que pueden ver los demás (Cloud Firestore,
/// `publicProfiles/{uid}`).
///
/// Es una copia reducida de `users/{uid}` sin el correo, para que los amigos
/// vean el nombre, el nivel y la cabeza del personaje (su foto de perfil)
/// sin poder leer datos privados.
class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.username,
    this.friendCode = '',
    this.experience = 0,
    this.photoUrl,
    this.skinTone = SkinTone.defaultIndex,
    this.eyes = EyeStyle.defaultStyle,
    this.eyeColor = EyeColor.defaultIndex,
    this.mouth = MouthStyle.defaultStyle,
    this.mouthColor = MouthColor.defaultIndex,
    this.shirt = ShirtStyle.defaultStyle,
    this.accessory,
    this.hair,
    this.hairColor = HairColor.defaultIndex,
    this.avatarColor = AvatarColor.defaultIndex,
    this.facePhoto,
  });

  final String uid;
  final String username;
  final String friendCode;

  /// XP acumulada; el nivel se calcula con `ExperienceCalculator`.
  final int experience;

  /// Foto de perfil (opcional).
  final String? photoUrl;

  /// Cómo se ve la cabeza del personaje: posiciones en SkinTone, EyeColor,
  /// MouthColor y AvatarColor, y los estilos de ojos y boca.
  final int skinTone;
  final EyeStyle eyes;
  final int eyeColor;
  final MouthStyle mouth;
  final int mouthColor;

  /// Camisa y accesorio puestos (el accesorio se ve en la foto de perfil).
  final ShirtStyle shirt;
  final AccessoryStyle? accessory;

  /// Cabello puesto (null = ninguno) y la posición de su color en HairColor.
  final HairStyle? hair;
  final int hairColor;
  final int avatarColor;

  /// La foto de la cara del jugador, solo si la está usando: con ella se
  /// dibujan sus ojos y su boca en lugar de los estilos de arriba.
  final FacePhoto? facePhoto;

  factory PublicProfile.fromMap(String uid, Map<String, dynamic> map) {
    return PublicProfile(
      uid: uid,
      username: map['username'] as String? ?? '',
      friendCode: map['friendCode'] as String? ?? '',
      experience: (map['experience'] as num?)?.toInt() ?? 0,
      photoUrl: map['photoUrl'] as String?,
      skinTone: SkinTone.clamp(
        (map['skinTone'] as num?)?.toInt() ?? SkinTone.defaultIndex,
      ),
      eyes: EyeStyle.fromNumber((map['eyes'] as num?)?.toInt()),
      eyeColor: EyeColor.clamp(
        (map['eyeColor'] as num?)?.toInt() ?? EyeColor.defaultIndex,
      ),
      mouth: MouthStyle.fromNumber((map['mouth'] as num?)?.toInt()),
      mouthColor: MouthColor.clamp(
        (map['mouthColor'] as num?)?.toInt() ?? MouthColor.defaultIndex,
      ),
      shirt: ShirtStyle.fromId((map['shirt'] as num?)?.toInt()),
      accessory: AccessoryStyle.fromId((map['accessory'] as num?)?.toInt()),
      hair: HairStyle.fromId((map['hair'] as num?)?.toInt()),
      hairColor: HairColor.clamp(
        (map['hairColor'] as num?)?.toInt() ?? HairColor.defaultIndex,
      ),
      avatarColor: AvatarColor.clamp(
        (map['avatarColor'] as num?)?.toInt() ?? AvatarColor.defaultIndex,
      ),
      facePhoto: FacePhoto.fromStored(map['facePhoto']),
    );
  }

  Map<String, dynamic> toMap() => {
    'username': username,
    'friendCode': friendCode,
    'experience': experience,
    'photoUrl': photoUrl,
    'skinTone': skinTone,
    'eyes': eyes.number,
    'eyeColor': eyeColor,
    'mouth': mouth.number,
    'mouthColor': mouthColor,
    'shirt': shirt.id,
    'accessory': accessory?.id ?? 0,
    'hair': hair?.id ?? 0,
    'hairColor': hairColor,
    'avatarColor': avatarColor,
    'facePhoto': facePhoto?.base64,
  };

  /// Si guardar [other] cambiaría algo (para no escribir de más).
  bool sameAs(PublicProfile other) {
    return uid == other.uid &&
        username == other.username &&
        friendCode == other.friendCode &&
        experience == other.experience &&
        photoUrl == other.photoUrl &&
        skinTone == other.skinTone &&
        eyes == other.eyes &&
        eyeColor == other.eyeColor &&
        mouth == other.mouth &&
        mouthColor == other.mouthColor &&
        shirt == other.shirt &&
        accessory == other.accessory &&
        hair == other.hair &&
        hairColor == other.hairColor &&
        avatarColor == other.avatarColor &&
        facePhoto == other.facePhoto;
  }
}
