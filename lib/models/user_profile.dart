import 'package:party_tricks/models/accessory_style.dart';
import 'package:party_tricks/models/avatar_color.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/eye_style.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/mouth_style.dart';
import 'package:party_tricks/models/shirt_style.dart';
import 'package:party_tricks/models/skin_tone.dart';

/// Perfil permanente del jugador (vive en Cloud Firestore, colección `users`).
///
/// La contraseña nunca se guarda aquí: la gestiona Firebase Authentication.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    required this.friendCode,
    this.experience = 0,
    this.coins = 0,
    this.diamonds = 0,
    this.extraDice = 0,
    this.skinTone = SkinTone.defaultIndex,
    this.eyes = EyeStyle.defaultStyle,
    this.eyeColor = EyeColor.defaultIndex,
    this.ownedEyes = const {},
    this.mouth = MouthStyle.defaultStyle,
    this.mouthColor = MouthColor.defaultIndex,
    this.ownedMouths = const {},
    this.shirt = ShirtStyle.defaultStyle,
    this.ownedShirts = const {},
    this.accessory,
    this.ownedAccessories = const {},
    this.avatarColor = AvatarColor.defaultIndex,
    this.facePhoto,
    this.useFacePhoto = true,
    this.usernameChangedAt,
  });

  /// Identificador de Firebase Authentication.
  final String uid;
  final String email;

  /// Único (sin distinguir mayúsculas); lo ven los demás jugadores.
  final String username;

  /// Único; sirve para que otros jugadores te agreguen como amigo.
  final String friendCode;

  /// XP acumulada. El nivel se calcula a partir de ella.
  final int experience;

  /// Monedas de la cuenta.
  final int coins;

  /// Diamantes de la cuenta.
  final int diamonds;

  /// Dados extra consumibles que ganó en los cofres.
  final int extraDice;

  /// Posición del tono de piel en [SkinTone] (0 = el más claro).
  final int skinTone;

  /// Ojos equipados. En Firestore se guarda su número (campo `eyes`).
  final EyeStyle eyes;

  /// Posición del color de ojos en [EyeColor] (0 = el dibujo original).
  final int eyeColor;

  /// Números de los ojos que compró en la Tienda (campo `ownedEyes`). Los
  /// gratis no se guardan: los tiene todo el mundo.
  final Set<int> ownedEyes;

  /// Si puede ponerse [style]: es gratis o ya lo compró.
  bool ownsEyes(EyeStyle style) =>
      style.isFree || ownedEyes.contains(style.number);

  /// Boca equipada. En Firestore se guarda su número (campo `mouth`).
  final MouthStyle mouth;

  /// Posición del color de boca en [MouthColor] (0 = sin color: toma el
  /// tono de piel).
  final int mouthColor;

  /// Números de las bocas que compró en la Tienda (campo `ownedMouths`).
  /// Las gratis no se guardan: las tiene todo el mundo.
  final Set<int> ownedMouths;

  /// Camisa puesta. En Firestore se guarda su id (campo `shirt`).
  final ShirtStyle shirt;

  /// Ids de las camisas que compró en la Tienda (campo `ownedShirts`). La
  /// de inicio no se guarda: la tiene todo el mundo.
  final Set<int> ownedShirts;

  /// Si puede ponerse [style]: es gratis o ya la compró.
  bool ownsShirt(ShirtStyle style) =>
      style.isFree || ownedShirts.contains(style.id);

  /// Accesorio puesto, o null si no lleva ninguno. En Firestore se guarda su
  /// id, o 0 si no lleva (campo `accessory`).
  final AccessoryStyle? accessory;

  /// Ids de los accesorios que compró (campo `ownedAccessories`).
  final Set<int> ownedAccessories;

  /// Si puede ponerse [style]: ya lo compró.
  bool ownsAccessory(AccessoryStyle style) =>
      style.isFree || ownedAccessories.contains(style.id);

  /// Posición del color de fondo de la foto de perfil en [AvatarColor].
  final int avatarColor;

  /// La foto de la cara que el jugador guardó (campo `facePhoto`), si la hay.
  final FacePhoto? facePhoto;

  /// Si quiere ver su foto en la cara del personaje en lugar de los ojos y
  /// la boca (campo `useFacePhoto`).
  final bool useFacePhoto;

  /// La foto que se dibuja: la guardada, si la está usando.
  FacePhoto? get shownFacePhoto => useFacePhoto ? facePhoto : null;

  /// Si puede ponerse [style]: es gratis o ya la compró.
  bool ownsMouth(MouthStyle style) =>
      style.isFree || ownedMouths.contains(style.number);

  /// Última vez que cambió el nombre de usuario en Ajustes (null si nunca).
  final DateTime? usernameChangedAt;

  /// El [uid] es el id del documento, por eso no va dentro del mapa.
  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    final changed = map['usernameChangedAt'];
    return UserProfile(
      uid: uid,
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? '',
      friendCode: map['friendCode'] as String? ?? '',
      experience: (map['experience'] as num?)?.toInt() ?? 0,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      diamonds: (map['diamonds'] as num?)?.toInt() ?? 0,
      extraDice: (map['extraDice'] as num?)?.toInt() ?? 0,
      skinTone: SkinTone.clamp(
        (map['skinTone'] as num?)?.toInt() ?? SkinTone.defaultIndex,
      ),
      eyes: EyeStyle.fromNumber((map['eyes'] as num?)?.toInt()),
      eyeColor: EyeColor.clamp(
        (map['eyeColor'] as num?)?.toInt() ?? EyeColor.defaultIndex,
      ),
      ownedEyes: {
        for (final value in map['ownedEyes'] as List? ?? const [])
          if (value is num) value.toInt(),
      },
      mouth: MouthStyle.fromNumber((map['mouth'] as num?)?.toInt()),
      mouthColor: MouthColor.clamp(
        (map['mouthColor'] as num?)?.toInt() ?? MouthColor.defaultIndex,
      ),
      ownedMouths: {
        for (final value in map['ownedMouths'] as List? ?? const [])
          if (value is num) value.toInt(),
      },
      shirt: ShirtStyle.fromId((map['shirt'] as num?)?.toInt()),
      ownedShirts: {
        for (final value in map['ownedShirts'] as List? ?? const [])
          if (value is num) value.toInt(),
      },
      accessory: AccessoryStyle.fromId((map['accessory'] as num?)?.toInt()),
      ownedAccessories: {
        for (final value in map['ownedAccessories'] as List? ?? const [])
          if (value is num) value.toInt(),
      },
      avatarColor: AvatarColor.clamp(
        (map['avatarColor'] as num?)?.toInt() ?? AvatarColor.defaultIndex,
      ),
      facePhoto: FacePhoto.fromStored(map['facePhoto']),
      useFacePhoto: map['useFacePhoto'] as bool? ?? true,
      usernameChangedAt: changed is num
          ? DateTime.fromMillisecondsSinceEpoch(changed.toInt())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'friendCode': friendCode,
      'experience': experience,
      'coins': coins,
      'diamonds': diamonds,
      'extraDice': extraDice,
      'skinTone': skinTone,
      'eyes': eyes.number,
      'eyeColor': eyeColor,
      'ownedEyes': ownedEyes.toList()..sort(),
      'mouth': mouth.number,
      'mouthColor': mouthColor,
      'ownedMouths': ownedMouths.toList()..sort(),
      'shirt': shirt.id,
      'ownedShirts': ownedShirts.toList()..sort(),
      'accessory': accessory?.id ?? 0,
      'ownedAccessories': ownedAccessories.toList()..sort(),
      'avatarColor': avatarColor,
      if (facePhoto != null) 'facePhoto': facePhoto!.base64,
      'useFacePhoto': useFacePhoto,
      if (usernameChangedAt != null)
        'usernameChangedAt': usernameChangedAt!.millisecondsSinceEpoch,
    };
  }

  UserProfile copyWith({
    String? email,
    String? username,
    String? friendCode,
    int? experience,
    int? coins,
    int? diamonds,
    int? extraDice,
    int? skinTone,
    EyeStyle? eyes,
    int? eyeColor,
    Set<int>? ownedEyes,
    MouthStyle? mouth,
    int? mouthColor,
    Set<int>? ownedMouths,
    ShirtStyle? shirt,
    Set<int>? ownedShirts,
    AccessoryStyle? accessory,
    bool clearAccessory = false,
    Set<int>? ownedAccessories,
    int? avatarColor,
    FacePhoto? facePhoto,
    bool clearFacePhoto = false,
    bool? useFacePhoto,
    DateTime? usernameChangedAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      username: username ?? this.username,
      friendCode: friendCode ?? this.friendCode,
      experience: experience ?? this.experience,
      coins: coins ?? this.coins,
      diamonds: diamonds ?? this.diamonds,
      extraDice: extraDice ?? this.extraDice,
      skinTone: skinTone ?? this.skinTone,
      eyes: eyes ?? this.eyes,
      eyeColor: eyeColor ?? this.eyeColor,
      ownedEyes: ownedEyes ?? this.ownedEyes,
      mouth: mouth ?? this.mouth,
      mouthColor: mouthColor ?? this.mouthColor,
      ownedMouths: ownedMouths ?? this.ownedMouths,
      shirt: shirt ?? this.shirt,
      ownedShirts: ownedShirts ?? this.ownedShirts,
      accessory: clearAccessory ? null : accessory ?? this.accessory,
      ownedAccessories: ownedAccessories ?? this.ownedAccessories,
      avatarColor: avatarColor ?? this.avatarColor,
      facePhoto: clearFacePhoto ? null : facePhoto ?? this.facePhoto,
      useFacePhoto: useFacePhoto ?? this.useFacePhoto,
      usernameChangedAt: usernameChangedAt ?? this.usernameChangedAt,
    );
  }
}
