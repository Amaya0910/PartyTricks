import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Campo de texto gris de las tarjetas de inicio de sesión y registro.
///
/// Si [isPassword] es true, el texto se oculta y aparece un ojo al lado para
/// mostrarlo u ocultarlo.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(8));

  bool _hidden = true;

  void _toggleVisibility() => setState(() => _hidden = !_hidden);

  @override
  Widget build(BuildContext context) {
    final obscure = widget.isPassword && _hidden;

    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: obscure,
      enableSuggestions: !widget.isPassword,
      autocorrect: !widget.isPassword,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      cursorColor: AppColors.authAccent,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.authText,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintMaxLines: 1,
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.authHint,
          overflow: TextOverflow.ellipsis,
        ),
        filled: true,
        fillColor: AppColors.authField,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: _toggleVisibility,
                tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.authHint,
                  size: 20,
                ),
              )
            : null,
        border: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: _radius,
          borderSide: BorderSide(color: AppColors.authAccent, width: 2),
        ),
      ),
    );
  }
}
