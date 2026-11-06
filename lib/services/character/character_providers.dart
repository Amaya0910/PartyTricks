import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/character/character_service.dart';
import 'package:party_tricks/services/character/face_camera.dart';
import 'package:party_tricks/services/character/face_image_service.dart';
import 'package:party_tricks/services/character/firebase_character_service.dart';

final characterServiceProvider = Provider<CharacterService>(
  (ref) => FirebaseCharacterService(FirebaseFirestore.instance),
);

final faceCameraProvider = Provider<FaceCamera>((ref) => PluginFaceCamera());

final faceImageServiceProvider = Provider<FaceImageService>(
  (ref) => ImagePickerFaceImageService(),
);
