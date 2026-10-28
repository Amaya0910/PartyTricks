import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/social/public_profile.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/social/social_providers.dart';

/// Mantiene `publicProfiles/{uid}` igual al perfil del jugador (sin el
/// correo). Solo escribe cuando algo cambió.
class PublicProfileController {
  PublicProfileController(this._ref);

  final Ref _ref;
  PublicProfile? _lastPublished;

  /// Copia de [profile] que pueden ver los demás.
  static PublicProfile publicOf(UserProfile profile) {
    return PublicProfile(
      uid: profile.uid,
      username: profile.username,
      friendCode: profile.friendCode,
      experience: profile.experience,
    );
  }

  /// Publica [profile] si cambió desde la última vez. Si falla, no
  /// interrumpe al jugador: se intenta en el siguiente cambio.
  Future<void> sync(UserProfile profile) async {
    final next = publicOf(profile);
    final last = _lastPublished;
    if (last != null && last.sameAs(next)) return;
    try {
      await _ref.read(profileDirectoryProvider).publish(next);
      _lastPublished = next;
    } catch (error) {
      debugPrint('No se pudo publicar el perfil: $error');
    }
  }
}

final publicProfileControllerProvider = Provider<PublicProfileController>(
  PublicProfileController.new,
);
