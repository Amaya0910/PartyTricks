import 'package:flutter/material.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/animated_mode_switch.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';
import 'package:party_tricks/widgets/step_dot_slider.dart';

/// "Alista tu party": opciones para crear una sala.
/// Devuelve la configuración o null si se cierra.
class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({super.key});

  static Future<RoomSettings?> show(BuildContext context) {
    return showBlurredDialog<RoomSettings>(
      context,
      builder: (_) => const CreateRoomDialog(),
    );
  }

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  static const int _defaultPlayers = 3;
  static const int _defaultRounds = 10;

  /// Los deslizadores dibujan un punto por cada valor desde 1.
  static const int _firstDot = 1;

  bool _isPrivate = true;
  int _maxPlayers = _defaultPlayers;
  int _rounds = _defaultRounds;

  RoomSettings _buildSettings() {
    return RoomSettings(
      isPublic: !_isPrivate,
      maxPlayers: _maxPlayers,
      rounds: _rounds,
    );
  }

  void _submit() => Navigator.of(context).pop(_buildSettings());

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      title: 'Alista tu party',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingLabel('Jugadores: $_maxPlayers'),
            const SizedBox(height: 8),
            StepDotSlider(
              start: _firstDot,
              min: Room.minPlayers,
              max: Room.maxAllowedPlayers,
              value: _maxPlayers,
              onChanged: (value) => setState(() => _maxPlayers = value),
            ),
            const SizedBox(height: 20),
            _SettingLabel('Rondas: $_rounds'),
            const SizedBox(height: 8),
            StepDotSlider(
              start: _firstDot,
              min: Room.minRounds,
              max: Room.maxRounds,
              value: _rounds,
              dotSize: 7,
              showLine: false,
              onChanged: (value) => setState(() => _rounds = value),
            ),
            const SizedBox(height: 20),
            _VisibilityRow(
              isPrivate: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
            ),
            const SizedBox(height: 24),
            _CreateButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta azul en forma de píldora ("Jugadores: 3", "Rondas: 10").
class _SettingLabel extends StatelessWidget {
  const _SettingLabel(this.text);

  final String text;

  static const double _widthFactor = 0.68;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: _widthFactor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.authAccent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.pillShadow,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Lista de invitados" con su subtítulo y el interruptor privado/público.
class _VisibilityRow extends StatelessWidget {
  const _VisibilityRow({required this.isPrivate, required this.onChanged});

  final bool isPrivate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lista de invitados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authAccent,
                ),
              ),
              Text(
                isPrivate ? 'Solo con código' : 'Fiesta para todos (pública)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.authHint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AnimatedModeSwitch(isPrivate: isPrivate, onChanged: onChanged),
      ],
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.authAccent,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: const Text(
          'Crear',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}