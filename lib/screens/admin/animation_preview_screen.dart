import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/character_look_controller.dart';
import 'package:party_tricks/models/character_look.dart';
import 'package:party_tricks/models/skin_tone.dart';
import 'package:party_tricks/screens/admin/admin_page.dart';
import 'package:party_tricks/widgets/character/character_clips.dart';
import 'package:party_tricks/widgets/settings_section.dart';

/// Vista previa de todas las animaciones del personaje ([CharacterClip]):
/// se elige una, se ve en bucle y se puede pausar, cambiarle la velocidad,
/// recorrerla cuadro por cuadro y voltearla. Nada de lo que se toca aquí se
/// guarda.
///
/// Por defecto se ve con el personaje del administrador tal como lo tiene
/// puesto (piel, ojos, boca, camisa, accesorio y foto de la cara); también
/// se puede probar con el aspecto de inicio y otro tono de piel.
class AnimationPreviewScreen extends ConsumerStatefulWidget {
  const AnimationPreviewScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const AnimationPreviewScreen());

  @override
  ConsumerState<AnimationPreviewScreen> createState() =>
      _AnimationPreviewScreenState();
}

class _AnimationPreviewScreenState extends ConsumerState<AnimationPreviewScreen>
    with SingleTickerProviderStateMixin {
  static const _speeds = [0.25, 0.5, 1.0, 2.0];

  /// Cuántos cuadros se muestran en la tira de fases.
  static const _frames = 6;

  CharacterClip _clip = CharacterClip.values.first;
  double _speed = 1;
  bool _playing = true;
  bool _faceRight = true;
  bool _useMine = true;
  int _tone = SkinTone.defaultIndex;

  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: _clip.period,
  )..repeat();

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  CharacterLook get _look => _useMine
      ? ref.watch(characterLookProvider)
      : CharacterLook.standard.copyWith(skinTone: SkinTone.colorOf(_tone));

  void _applySpeed() {
    _phase.duration = Duration(
      microseconds: (_clip.period.inMicroseconds / _speed).round(),
    );
    if (_playing) _phase.repeat();
  }

  void _pick(CharacterClip clip) {
    setState(() {
      _clip = clip;
      _phase.value = 0;
    });
    _applySpeed();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _phase.repeat();
    } else {
      _phase.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final look = _look;
    return AdminPage(
      title: 'Animaciones',
      children: [
        SettingsSection(
          title: 'Animación',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final clip in CharacterClip.values)
                  ChoiceChip(
                    label: Text(clip.title),
                    selected: clip == _clip,
                    onSelected: (_) => _pick(clip),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_clip.description),
          ],
        ),
        SettingsSection(
          title: 'Vista previa',
          children: [
            SizedBox(
              height: 280,
              child: _clip.build(
                key: ValueKey((_clip, look, _faceRight)),
                look: look,
                phase: _phase,
                faceRight: _faceRight,
              ),
            ),
            Row(
              children: [
                IconButton.filled(
                  tooltip: _playing ? 'Pausar' : 'Reproducir',
                  onPressed: _togglePlay,
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _phase,
                    builder: (context, _) => Slider(
                      value: _phase.value.clamp(0, 1).toDouble(),
                      onChanged: (value) {
                        // Al arrastrar se pausa y se ve ese cuadro.
                        setState(() => _playing = false);
                        _phase.stop();
                        _phase.value = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final speed in _speeds)
                  ChoiceChip(
                    label: Text('${speed}x'),
                    selected: speed == _speed,
                    onSelected: (_) {
                      setState(() => _speed = speed);
                      _applySpeed();
                    },
                  ),
                if (_clip.canFlip)
                  FilterChip(
                    label: const Text('Mirar a la izquierda'),
                    selected: !_faceRight,
                    onSelected: (left) => setState(() => _faceRight = !left),
                  ),
              ],
            ),
          ],
        ),
        SettingsSection(
          title: 'Fases',
          children: [
            Row(
              children: [
                for (var i = 0; i < _frames; i++)
                  Expanded(
                    child: SizedBox(
                      height: 130,
                      child: _clip.build(
                        key: ValueKey((_clip, i, look, _faceRight)),
                        look: look,
                        phase: AlwaysStoppedAnimation(i / _frames),
                        faceRight: _faceRight,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        SettingsSection(
          title: 'Personaje',
          children: [
            // Sin SwitchListTile: las tarjetas tienen fondo propio y el efecto
            // de toque de un ListTile no se vería (ni cabría en ellas).
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Usar mi personaje, con lo que tengo puesto: piel, ojos, '
                    'boca, camisa y accesorio.',
                  ),
                ),
                Switch(
                  value: _useMine,
                  onChanged: (value) => setState(() => _useMine = value),
                ),
              ],
            ),
            if (!_useMine) ...[
              const Text('Tono de piel'),
              Slider(
                value: _tone.toDouble(),
                min: 0,
                max: (SkinTone.count - 1).toDouble(),
                divisions: SkinTone.count - 1,
                label: 'Tono ${_tone + 1}',
                onChanged: (value) => setState(() => _tone = value.round()),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
