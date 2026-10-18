import 'package:flutter/material.dart';
import 'package:party_tricks/services/rooms/room_code_generator.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Pide el código de una sala privada. Devuelve el código o null si se cierra.
class JoinCodeDialog extends StatefulWidget {
  const JoinCodeDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const JoinCodeDialog(),
    );
  }

  @override
  State<JoinCodeDialog> createState() => _JoinCodeDialogState();
}

class _JoinCodeDialogState extends State<JoinCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unirse a Party'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: RoomCodeGenerator.length,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: 'Código de la sala'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.menuButton),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Entrar'),
        ),
      ],
    );
  }
}
