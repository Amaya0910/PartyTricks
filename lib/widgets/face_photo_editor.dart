import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/eyes_controller.dart';
import 'package:party_tricks/controllers/face_photo_controller.dart';
import 'package:party_tricks/controllers/mouth_controller.dart';
import 'package:party_tricks/controllers/skin_tone_controller.dart';
import 'package:party_tricks/models/eye_color.dart';
import 'package:party_tricks/models/face_photo.dart';
import 'package:party_tricks/models/mouth_color.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/services/character/character_service.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/animated_character.dart';
import 'package:party_tricks/widgets/character/head_shape.dart';
import 'package:party_tricks/widgets/face_photo_sheet.dart';

/// Editor de la foto: se mueve con un dedo, se acerca y se gira con dos, o con
/// los controles de abajo. Al lado, tu personaje con el resultado real.
class FacePhotoEditor extends ConsumerStatefulWidget {
  const FacePhotoEditor({
    super.key,
    required this.source,
    required this.initialCrop,
    required this.onRetake,
    required this.onSaved,
  });

  final FaceSourceImage source;
  final FaceCrop initialCrop;

  /// Volver a tomar la foto.
  final VoidCallback onRetake;

  /// Avisa cuando la foto ya quedó guardada.
  final VoidCallback onSaved;

  @override
  ConsumerState<FacePhotoEditor> createState() => _FacePhotoEditorState();
}

class _FacePhotoEditorState extends ConsumerState<FacePhotoEditor> {
  late FaceCrop _crop = widget.initialCrop.clamped(
    widget.source.width,
    widget.source.height,
  );
  late FaceCrop _gestureStart = _crop;
  Offset _gestureFocal = Offset.zero;

  /// Resultado para ver en el personaje.
  FacePhoto? _preview;

  /// Sube con cada recorte: si llega uno viejo, se ignora.
  int _renderId = 0;
  bool _busy = false;
  String? _error;

  /// Giro máximo de los controles.
  static const double _maxTurn = math.pi;

  @override
  void initState() {
    super.initState();
    _refreshPreview();
  }

  FaceCrop _fit(FaceCrop crop) =>
      crop.clamped(widget.source.width, widget.source.height);

  Future<void> _refreshPreview() async {
    final id = ++_renderId;
    try {
      final photo = await ref
          .read(facePhotoControllerProvider)
          .render(widget.source, _crop);
      if (mounted && id == _renderId) setState(() => _preview = photo);
    } on CharacterException catch (e) {
      if (mounted && id == _renderId) setState(() => _error = e.message);
    }
  }

  void _change(FaceCrop crop) {
    setState(() => _crop = _fit(crop));
    _refreshPreview();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final controller = ref.read(facePhotoControllerProvider);
    try {
      await controller.save(await controller.render(widget.source, _crop));
      if (mounted) widget.onSaved();
    } on CharacterException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Misma escena de la cámara: el visor de borde a borde y la hoja debajo.
    return ColoredBox(
      color: AppColors.wardrobeInk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) => _viewport(
                  Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
            ),
          ),
          FacePhotoSheet(
            title: 'Ajusta tu foto',
            message: 'Lo que quede dentro de la silueta será tu cara',
            child: _controls(),
          ),
        ],
      ),
    );
  }

  Widget _viewport(Size area) {
    final side = math.min(area.width - 24, area.height - 16);
    final zone = Rect.fromCenter(
      center: area.center(Offset.zero),
      width: side,
      height: side,
    );
    final source = widget.source;
    final fit = side / math.min(source.width, source.height);
    final transform = Matrix4.identity()
      ..translateByDouble(_crop.dx * side, _crop.dy * side, 0, 1)
      ..rotateZ(_crop.rotation)
      ..scaleByDouble(
        _crop.mirrored ? -_crop.scale : _crop.scale,
        _crop.scale,
        1,
        1,
      );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        _gestureStart = _crop;
        _gestureFocal = details.focalPoint;
      },
      onScaleUpdate: (details) {
        final moved = details.focalPoint - _gestureFocal;
        setState(() {
          _crop = _fit(
            _gestureStart.copyWith(
              scale: _gestureStart.scale * details.scale,
              rotation: _gestureStart.rotation + details.rotation,
              dx: _gestureStart.dx + moved.dx / side,
              dy: _gestureStart.dy + moved.dy / side,
            ),
          );
        });
      },
      onScaleEnd: (_) => _refreshPreview(),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFE2E6EA)),
            OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Transform(
                alignment: Alignment.center,
                transform: transform,
                child: SizedBox(
                  width: source.width * fit,
                  height: source.height * fit,
                  child: Image.memory(
                    source.bytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
            CustomPaint(
              painter: HeadGuidePainter(
                zone: zone,
                scrim: AppColors.wardrobeInk.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 126,
                child: _CharacterResult(photo: _preview),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SliderRow(
                      icon: Icons.zoom_in,
                      label: 'Zoom',
                      value: _crop.scale,
                      min: FaceCrop.minScale,
                      max: FaceCrop.maxScale,
                      onChanged: (value) => setState(
                        () => _crop = _fit(_crop.copyWith(scale: value)),
                      ),
                      onChangeEnd: (_) => _refreshPreview(),
                    ),
                    _SliderRow(
                      icon: Icons.rotate_right,
                      label: 'Giro',
                      value: _turn(_crop.rotation),
                      min: -_maxTurn,
                      max: _maxTurn,
                      onChanged: (value) => setState(
                        () => _crop = _crop.copyWith(rotation: value),
                      ),
                      onChangeEnd: (_) => _refreshPreview(),
                    ),
                    // Wrap: en pantallas angostas los botones bajan de línea.
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _change(
                            _crop.copyWith(mirrored: !_crop.mirrored),
                          ),
                          icon: const Icon(Icons.flip),
                          label: const Text('Voltear'),
                        ),
                        TextButton.icon(
                          onPressed: () => _change(widget.initialCrop),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Restablecer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authError,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : widget.onRetake,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: AppColors.authText,
                    side: const BorderSide(
                      color: AppColors.authAccent,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                  child: const Text('Repetir'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: AppColors.activeButton,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Deja el giro entre media vuelta a cada lado, para el control.
  double _turn(double rotation) {
    final turned = (rotation + _maxTurn) % (2 * _maxTurn);
    return turned - _maxTurn;
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.authText),
        Expanded(
          child: Slider(
            semanticFormatterCallback: (_) => label,
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}

/// Tu personaje con la foto recortada, tal como quedará.
class _CharacterResult extends ConsumerWidget {
  const _CharacterResult({required this.photo});

  final FacePhoto? photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedCharacter(
      skinTone: SkinTone.colorOf(ref.watch(skinToneProvider)),
      eyes: ref.watch(eyeStyleProvider),
      eyeColor: EyeColor.colorOf(ref.watch(eyeColorProvider)),
      mouth: ref.watch(mouthStyleProvider),
      mouthColor: MouthColor.colorOf(ref.watch(mouthColorProvider)),
      facePhoto: photo,
    );
  }
}
