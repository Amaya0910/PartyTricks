import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Una cara de la tarjeta de acceso: cabecera azul con el título, los campos,
/// el botón principal y el enlace para pasar a la otra cara.
///
/// Solo dibuja; la lógica vive en [LoginCard] y [RegisterCard].
class AuthCardFace extends StatelessWidget {
  const AuthCardFace({
    super.key,
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    required this.switchLabel,
    required this.onSwitch,
    this.errorMessage,
    this.isLoading = false,
  });

  final String title;
  final List<Widget> fields;
  final String submitLabel;
  final VoidCallback onSubmit;
  final String switchLabel;
  final VoidCallback onSwitch;
  final String? errorMessage;
  final bool isLoading;

  static const double _borderWidth = 3;
  static const double _radius = 28;
  static const double _fieldGap = 14;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.authCardBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColors.authAccent, width: _borderWidth),
        boxShadow: const [
          BoxShadow(
            color: AppColors.authShadow,
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - _borderWidth),
        child: Column(
          children: [
            _Header(title: title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                child: Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(height: _fieldGap),
                      fields[i],
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.authError,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 4, 40, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SubmitButton(
                    label: submitLabel,
                    isLoading: isLoading,
                    onPressed: onSubmit,
                  ),
                  TextButton(
                    onPressed: isLoading ? null : onSwitch,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.authText,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      switchLabel,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.authAccent,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.authOnAccent,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        backgroundColor: AppColors.authAccent,
        disabledBackgroundColor: AppColors.authAccent,
        foregroundColor: AppColors.authOnAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.authOnAccent,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
