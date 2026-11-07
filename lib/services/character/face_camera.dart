import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:party_tricks/services/character/character_service.dart';

/// La cámara en vivo de la pantalla de la foto. La versión real usa el
/// paquete `camera`; en las pruebas se puede cambiar por una falsa.
abstract class FaceCamera {
  /// Enciende la cámara. Lanza [CharacterException] con el mensaje a mostrar
  /// si no hay cámara o no dieron permiso.
  Future<void> open();

  /// Lo que ve la cámara. Solo después de [open].
  Widget preview();

  /// Ancho entre alto de [preview], con el celular vertical.
  double get aspectRatio;

  /// Si hay otra cámara a la cual cambiar.
  bool get canSwitch;

  /// Cambia entre la cámara frontal y la trasera.
  Future<void> switchCamera();

  /// Toma la foto. Lanza [CharacterException] si falla.
  Future<Uint8List> takePicture();

  /// Apaga la cámara. Se puede volver a llamar a [open].
  Future<void> close();
}

class PluginFaceCamera implements FaceCamera {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  CameraDescription? _current;

  @override
  Future<void> open() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw const CharacterException('Este celular no tiene cámara.');
      }
      _current ??= _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      await _start(_current!);
    } on CameraException catch (error) {
      await close();
      throw CharacterException(_messageFor(error));
    } on CharacterException {
      rethrow;
    } catch (_) {
      await close();
      throw const CharacterException('No se pudo abrir la cámara.');
    }
  }

  Future<void> _start(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    _controller = controller;
  }

  String _messageFor(CameraException error) {
    if (error.code.contains('Denied') || error.code.contains('denied')) {
      return 'Sin permiso para usar la cámara. Actívalo en los ajustes del '
          'celular o elige una foto de la galería.';
    }
    return 'No se pudo abrir la cámara.';
  }

  @override
  Widget preview() => CameraPreview(_controller!);

  // El paquete da ancho entre alto con el celular acostado.
  @override
  double get aspectRatio => 1 / _controller!.value.aspectRatio;

  @override
  bool get canSwitch => _cameras.length > 1;

  @override
  Future<void> switchCamera() async {
    if (!canSwitch) return;
    final direction = _current!.lensDirection;
    final next = _cameras.firstWhere(
      (camera) => camera.lensDirection != direction,
      orElse: () => _cameras.first,
    );
    await close();
    _current = next;
    try {
      await _start(next);
    } on CameraException catch (error) {
      throw CharacterException(_messageFor(error));
    }
  }

  @override
  Future<Uint8List> takePicture() async {
    try {
      final file = await _controller!.takePicture();
      return await file.readAsBytes();
    } catch (_) {
      throw const CharacterException('No se pudo tomar la foto.');
    }
  }

  @override
  Future<void> close() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }
}
