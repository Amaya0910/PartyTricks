import 'package:flutter/material.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Opciones para crear una sala. Devuelve la configuración o null si se cierra.
class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({super.key});

  static Future<RoomSettings?> show(BuildContext context) {
    return showDialog<RoomSettings>(
      context: context,
      builder: (_) => const CreateRoomDialog(),
    );
  }

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  bool _isPublic = false;
  int _maxPlayers = Room.maxAllowedPlayers;
  int _rounds = 10;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Party'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sala pública'),
            subtitle: Text(
              _isPublic ? 'Cualquiera puede entrar' : 'Solo con el código',
            ),
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
          ),
          Text('Jugadores: $_maxPlayers'),
          Slider(
            value: _maxPlayers.toDouble(),
            min: Room.minPlayers.toDouble(),
            max: Room.maxAllowedPlayers.toDouble(),
            divisions: Room.maxAllowedPlayers - Room.minPlayers,
            onChanged: (value) => setState(() => _maxPlayers = value.round()),
          ),
          Text('Rondas: $_rounds'),
          Slider(
            value: _rounds.toDouble(),
            min: Room.minRounds.toDouble(),
            max: Room.maxRounds.toDouble(),
            divisions: Room.maxRounds - Room.minRounds,
            onChanged: (value) => setState(() => _rounds = value.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.menuButton),
          onPressed: () => Navigator.of(context).pop(
            RoomSettings(
              isPublic: _isPublic,
              maxPlayers: _maxPlayers,
              rounds: _rounds,
            ),
          ),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
