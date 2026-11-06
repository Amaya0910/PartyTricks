import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/character/character_providers.dart';
import 'package:party_tricks/services/character/character_service.dart';
import 'package:party_tricks/services/character/face_camera.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/character/head_shape.dart';

/// La cámara en vivo con la silueta de la cabeza encima: lo que queda dentro
/// de la silueta es lo que se usa para la cara del personaje.
class FaceCameraView extends ConsumerStatefulWidget {
  const FaceCameraView({
    super.key,
    required this.onCaptured,
    required this.onGallery,
    required this.onBack,
  });

  /// Avisa con la foto y con el zoom que tenía en la pantalla, para que el
  /// editor la muestre igual a como se veía dentro de la silueta.
  final void Function(Uint8List bytes, double scale) onCaptured;
  final VoidCallback onGallery;
  final VoidCallback onBack;

  @override
  ConsumerState<FaceCameraView> createState() => _FaceCameraViewState();
}

class _FaceCameraViewState extends ConsumerState<FaceCameraView>
    with WidgetsBindingObserver {
  late final FaceCamera _camera = ref.read(faceCameraProvider);
  bool _ready = false;
  bool _busy = false;
  String? _error;

  /// Zoom de la foto respecto a la silueta, según lo último que se dibujó.
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.close();
    super.dispose();
  }

  // La cámara se suelta al salir de la app y se pide otra vez al volver.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      setState(() => _ready = false);
      _camera.close();
    } else if (state == AppLifecycleState.resumed && !_ready) {
      _open();
    }
  }

  Future<void> _open() async {
    setState(() => _error = null);
    try {
      await _camera.open();
      if (mounted) setState(() => _ready = true);
    } on CharacterException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _switch() async {
    setState(() {
      _ready = false;
      _error = null;
    });
    try {
      await _camera.switchCamera();
      if (mounted) setState(() => _ready = true);
    } on CharacterException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _capture() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await _camera.takePicture();
      widget.onCaptured(bytes, _scale);
    } on CharacterException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.wardrobeInk,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => _viewfinder(
                  Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
            ),
            _controls(),
          ],
        ),
      ),
    );
  }

  Widget _viewfinder(Size area) {
    final side = math.min(area.width * 0.86, area.height * 0.7);
    final zone = Rect.fromCenter(
      center: area.center(Offset.zero),
      width: side,
      height: side,
    );

    Widget? preview;
    if (_ready) {
      // La cámara llena la pantalla sin deformarse: lo que sobra se corta.
      final ratio = _camera.aspectRatio;
      final width = math.max(area.width, area.height * ratio);
      final height = width / ratio;
      _scale = math.max(1, math.min(width, height) / side);
      preview = ClipRect(
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
          child: SizedBox(
            width: width,
            height: height,
            child: _camera.preview(),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ?preview,
        CustomPaint(
          painter: HeadGuidePainter(
            zone: zone,
            scrim: AppColors.wardrobeInk.withValues(alpha: 0.6),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: IconButton(
            tooltip: 'Volver',
            onPressed: widget.onBack,
            icon: const Icon(Icons.chevron_left, size: 34),
            color: AppColors.white,
          ),
        ),
        Positioned(
          top: 14,
          left: 60,
          right: 16,
          child: Text(
            _error ??
                'Pon tu cara dentro de la silueta y alinea tus ojos y tu boca '
                    'con las líneas',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Galería',
            onPressed: _busy ? null : widget.onGallery,
            icon: const Icon(Icons.photo_library, size: 32),
            color: AppColors.white,
          ),
          Semantics(
            button: true,
            label: 'Tomar foto',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _ready && !_busy ? _capture : null,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ready && !_busy
                      ? AppColors.white
                      : AppColors.authHint,
                  border: Border.all(color: AppColors.authAccent, width: 5),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cambiar de cámara',
            onPressed: _ready && !_busy && _camera.canSwitch ? _switch : null,
            icon: const Icon(Icons.cameraswitch, size: 32),
            color: AppColors.white,
            disabledColor: AppColors.authHint,
          ),
        ],
      ),
    );
  }
}
