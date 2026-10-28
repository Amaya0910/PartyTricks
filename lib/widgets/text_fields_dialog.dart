import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';

/// Un campo del [TextFieldsDialog].
class DialogField {
  const DialogField({
    required this.label,
    this.initialValue = '',
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
  });

  final String label;
  final String initialValue;

  /// Para contraseñas: oculta el texto.
  final bool obscure;
  final TextInputType keyboardType;
  final int? maxLength;
}

/// Diálogo con uno o varios campos de texto (cambiar nombre, cambiar
/// correo). Devuelve lo escrito en cada campo, o null si se cancela.
///
/// [validate] recibe los valores y devuelve el mensaje de error, o null si
/// están bien; el diálogo no se cierra mientras haya error.
class TextFieldsDialog extends StatefulWidget {
  const TextFieldsDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.confirmLabel,
    this.message,
    this.validate,
  });

  final String title;
  final List<DialogField> fields;
  final String confirmLabel;

  /// Texto opcional arriba de los campos.
  final String? message;
  final String? Function(List<String> values)? validate;

  static Future<List<String>?> show(
    BuildContext context, {
    required String title,
    required List<DialogField> fields,
    required String confirmLabel,
    String? message,
    String? Function(List<String> values)? validate,
  }) {
    return showBlurredDialog<List<String>>(
      context,
      builder: (_) => TextFieldsDialog(
        title: title,
        fields: fields,
        confirmLabel: confirmLabel,
        message: message,
        validate: validate,
      ),
    );
  }

  @override
  State<TextFieldsDialog> createState() => _TextFieldsDialogState();
}

class _TextFieldsDialogState extends State<TextFieldsDialog> {
  late final List<TextEditingController> _controllers = [
    for (final field in widget.fields)
      TextEditingController(text: field.initialValue),
  ];
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    final values = [for (final c in _controllers) c.text];
    final error = widget.validate?.call(values);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    return DialogCard(
      title: widget.title,
      accent: AppColors.settingsAccent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message != null) ...[
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.authText),
              ),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < widget.fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              TextField(
                controller: _controllers[i],
                autofocus: i == 0,
                obscureText: widget.fields[i].obscure,
                keyboardType: widget.fields[i].keyboardType,
                maxLength: widget.fields[i].maxLength,
                textInputAction: i == widget.fields.length - 1
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: i == widget.fields.length - 1
                    ? (_) => _confirm()
                    : null,
                decoration: InputDecoration(
                  labelText: widget.fields[i].label,
                  filled: true,
                  fillColor: AppColors.authField,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.authError),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.settingsOn,
              ),
              onPressed: _confirm,
              child: Text(widget.confirmLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
