import 'package:flutter/material.dart';
import 'package:party_tricks/models/social/report_reason.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/blurred_dialog.dart';

/// Pide el motivo del reporte. Devuelve el motivo o null si se cancela.
class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key, required this.username});

  /// A quién se reporta, para el texto.
  final String username;

  static Future<ReportReason?> show(BuildContext context, String username) {
    return showBlurredDialog<ReportReason>(
      context,
      builder: (_) => ReportDialog(username: username),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _reason;

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      title: 'Reportar',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Por qué reportas a ${widget.username}? Un adulto revisará '
              'el reporte.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.authText),
            ),
            const SizedBox(height: 8),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      value: reason,
                      dense: true,
                      title: Text(reason.label),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.reject,
              ),
              onPressed: _reason == null
                  ? null
                  : () => Navigator.of(context).pop(_reason),
              child: const Text('Enviar reporte'),
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
