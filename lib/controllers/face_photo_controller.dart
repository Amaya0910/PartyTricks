import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// La foto que el jugador guardó, la esté usando o no.
final savedFacePhotoProvider = Provider<FacePhoto?>(
  (ref) => ref.watch(userProfileProvider).value?.facePhoto,
);

/// Si quiere ver su foto en el personaje en lugar de los ojos y la boca.
final useFacePhotoProvider = Provider<bool>(
  (ref) => ref.watch(userProfileProvider).value?.useFacePhoto ?? true,
);

/// La foto que se dibuja en la cara del personaje: la guardada, si la está
/// usando. Null si no hay foto o prefiere los ojos y la boca.
final facePhotoProvider = Provider<FacePhoto?>(
  (ref) => ref.watch(userProfileProvider).value?.shownFacePhoto,
);

/// Preparar, guardar, activar y quitar la foto de la cara.
class FacePhotoController {
  FacePhotoController(this._ref);

  final Ref _ref;

  /// Pide una foto de la galería, lista para editar. Null si cancela. Lanza
  /// [CharacterException] con el mensaje a mostrar.
  Future<FaceSourceImage?> pickFromGallery() =>
      _ref.read(faceImageServiceProvider).pickFromGallery();

  /// Deja lista para editar una foto de la cámara o la que ya está guardada.
  /// Lanza [CharacterException] con el mensaje a mostrar.
  Future<FaceSourceImage> prepare(Uint8List bytes) =>
      _ref.read(faceImageServiceProvider).prepare(bytes);

  /// Hace el recorte, pero **no lo guarda**: sirve para ver cómo queda.
  /// Lanza [CharacterException] con el mensaje a mostrar.
  Future<FacePhoto> render(FaceSourceImage source, FaceCrop crop) =>
      _ref.read(faceImageServiceProvider).render(source, crop);

  /// Guarda la foto y la activa. Lanza [CharacterException].
  Future<void> save(FacePhoto photo) async {
    final service = _ref.read(characterServiceProvider);
    final uid = _uid();
    await service.setFacePhoto(uid: uid, photo: photo);
    if (!_ref.read(useFacePhotoProvider)) {
      await service.setUseFacePhoto(uid: uid, use: true);
    }
  }

  /// Borra la foto guardada. Lanza [CharacterException].
  Future<void> remove() => _ref
      .read(characterServiceProvider)
      .setFacePhoto(uid: _uid(), photo: null);

  /// Cambia entre la foto y los ojos y la boca. Lanza [CharacterException].
  Future<void> setUse(bool use) async {
    if (use == _ref.read(useFacePhotoProvider)) return;
    await _ref
        .read(characterServiceProvider)
        .setUseFacePhoto(uid: _uid(), use: use);
  }

  String _uid() {
    final uid = _ref.read(userProfileProvider).value?.uid;
    if (uid == null) {
      throw const CharacterException('Inicia sesión para cambiar tu foto.');
    }
    return uid;
  }
}

final facePhotoControllerProvider = Provider<FacePhotoController>(
  FacePhotoController.new,
);
