import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/character_look_controller.dart';
import 'package:party_tricks/controllers/face_photo_controller.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/services/character/character_service.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/app_background.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/face_camera_view.dart';
import 'package:party_tricks/widgets/face_photo_editor.dart';
import 'package:party_tricks/widgets/face_photo_sheet.dart';
import 'package:party_tricks/widgets/my_avatar.dart';

enum _Stage { overview, camera, editor }

/// Pantalla de la foto de la cara. Tiene tres partes: lo que ya tienes (con
/// el interruptor y quitar la foto), la cámara con la silueta y el editor.
class FacePhotoScreen extends ConsumerStatefulWidget {
  const FacePhotoScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const FacePhotoScreen());
  }

  @override
  ConsumerState<FacePhotoScreen> createState() => _FacePhotoScreenState();
}

class _FacePhotoScreenState extends ConsumerState<FacePhotoScreen> {
  // Sin foto guardada, se va directo a la cámara.
  late _Stage _stage = ref.read(savedFacePhotoProvider) == null
      ? _Stage.camera
      : _Stage.overview;
  FaceSourceImage? _source;
  FaceCrop _crop = const FaceCrop();
  bool _busy = false;
  String? _error;

  void _back() {
    switch (_stage) {
      case _Stage.editor:
        setState(() => _stage = _Stage.camera);
      case _Stage.camera when ref.read(savedFacePhotoProvider) != null:
        setState(() => _stage = _Stage.overview);
      default:
        Navigator.of(context).pop();
    }
  }

  void _edit(FaceSourceImage source, FaceCrop crop) {
    setState(() {
      _source = source;
      _crop = crop;
      _stage = _Stage.editor;
    });
  }

  /// Hace [action] mostrando "cargando" y el error si falla.
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on CharacterException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _captured(Uint8List bytes, double scale) => _run(() async {
    final source = await ref.read(facePhotoControllerProvider).prepare(bytes);
    if (mounted) _edit(source, FaceCrop(scale: scale));
  });

  Future<void> _gallery() => _run(() async {
    final source = await ref
        .read(facePhotoControllerProvider)
        .pickFromGallery();
    if (source != null && mounted) _edit(source, const FaceCrop());
  });

  Future<void> _adjustSaved(FacePhoto saved) => _run(() async {
    final source = await ref
        .read(facePhotoControllerProvider)
        .prepare(saved.bytes);
    if (mounted) _edit(source, const FaceCrop());
  });

  Future<void> _remove() => _run(() async {
    await ref.read(facePhotoControllerProvider).remove();
    if (mounted) setState(() => _stage = _Stage.camera);
  });

  @override
  Widget build(BuildContext context) {
    final source = _source;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackground(),
            switch (_stage) {
              _Stage.camera => FaceCameraView(
                onCaptured: _captured,
                onGallery: _gallery,
                onBack: _back,
              ),
              _Stage.editor when source != null => FacePhotoEditor(
                source: source,
                initialCrop: _crop,
                onRetake: () => setState(() => _stage = _Stage.camera),
                onSaved: () => setState(() => _stage = _Stage.overview),
              ),
              _ => _Overview(
                busy: _busy,
                error: _error,
                onBack: _back,
                onRetake: () => setState(() {
                  _error = null;
                  _stage = _Stage.camera;
                }),
                onAdjust: _adjustSaved,
                onRemove: _remove,
              ),
            },
            if (_busy && _stage == _Stage.camera)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

/// Tu personaje de pie sobre las colinas del juego y, debajo, lo que se puede
/// hacer con la foto.
class _Overview extends ConsumerWidget {
  const _Overview({
    required this.busy,
    required this.error,
    required this.onBack,
    required this.onRetake,
    required this.onAdjust,
    required this.onRemove,
  });

  final bool busy;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onRetake;
  final ValueChanged<FacePhoto> onAdjust;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedFacePhotoProvider);

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const AppBackground(),
              const _CharacterScene(),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Tooltip(
                      message: 'Volver',
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.settingsReload,
                        ),
                        onPressed: onBack,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Volver'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        FacePhotoSheet(
          title: 'Tu foto',
          message: 'La ven los demás jugadores',
          trailing: const MyAvatar(size: 58),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.photo_camera,
                      label: 'Otra foto',
                      detail: 'Tómala o elígela',
                      card: AppColors.chestBasicCard,
                      strong: AppColors.chestBasicStrong,
                      onTap: busy ? null : onRetake,
                    ),
                  ),
                  if (saved != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.tune,
                        label: 'Ajustar',
                        detail: 'Mueve, gira o acerca',
                        card: AppColors.chestPartyCard,
                        strong: AppColors.chestPartyStrong,
                        onTap: busy ? null : () => onAdjust(saved),
                      ),
                    ),
                  ],
                ],
              ),
              if (saved != null) ...[
                const SizedBox(height: 12),
                _UsePhotoRow(busy: busy),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authError,
                  ),
                ),
              ],
              if (saved != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: busy ? null : onRemove,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.settingsDanger,
                    ),
                    child: const Text('Quitar mi foto'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// El personaje grande, con los pies sobre su sombra.
class _CharacterScene extends ConsumerWidget {
  const _CharacterScene();

  /// Dónde caen los pies en el lienzo, de -1 (arriba) a 1 (abajo).
  static const double _feet = 0.85;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AspectRatio(
            aspectRatio: kCharacterCanvas.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: const Alignment(0, _feet),
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 0.035,
                    child: const DecoratedBox(
                      decoration: ShapeDecoration(
                        color: AppColors.characterShadow,
                        shape: OvalBorder(),
                      ),
                    ),
                  ),
                ),
                AnimatedCharacter.fromLook(ref.watch(characterLookProvider)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una acción grande, con los colores de las tarjetas de los cofres.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.detail,
    required this.card,
    required this.strong,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color card;
  final Color strong;

  /// Null mientras se está guardando algo.
  final VoidCallback? onTap;

  static final BorderRadius _radius = BorderRadius.circular(16);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$label. $detail',
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Material(
          color: card,
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(color: strong, width: 2),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: _radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: strong),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authText,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Elegir entre la foto y los ojos y la boca, en una cápsula como las de las
/// monedas.
class _UsePhotoRow extends ConsumerWidget {
  const _UsePhotoRow({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final use = ref.watch(useFacePhotoProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.pillBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usar mi foto',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authText,
                  ),
                ),
                Text(
                  'En lugar de los ojos y la boca',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authHint,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: use,
            activeTrackColor: AppColors.settingsOn,
            onChanged: busy
                ? null
                : ref.read(facePhotoControllerProvider).setUse,
          ),
        ],
      ),
    );
  }
}
