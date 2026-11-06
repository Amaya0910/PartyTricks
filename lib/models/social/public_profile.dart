import 'package:party_tricks/models/avatar_color.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
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
    this.avatarColor = AvatarColor.defaultIndex,
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
  final int avatarColor;

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
      avatarColor: AvatarColor.clamp(
        (map['avatarColor'] as num?)?.toInt() ?? AvatarColor.defaultIndex,
      ),
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
    'avatarColor': avatarColor,
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
        avatarColor == other.avatarColor;
  }
}
