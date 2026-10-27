import 'package:flutter/foundation.dart';
import 'package:party_tricks/services/social/social_exception.dart';

/// Ejecuta [action] y convierte cualquier error inesperado (sin conexión,
/// permisos de Firestore...) en un [SocialException] con un mensaje claro.
/// Los [SocialException] pasan tal cual.
Future<T> guardSocial<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on SocialException {
    rethrow;
  } catch (error) {
    debugPrint('Amigos y chat: $error');
    throw const SocialException(
      'No se pudo completar. Revisa tu conexión e intenta de nuevo.',
    );
  }
}
