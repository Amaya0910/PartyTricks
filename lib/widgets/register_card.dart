import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/widgets/auth_card_face.dart';
import 'package:party_tricks/widgets/auth_text_field.dart';

/// Cara de registro. Igual que [LoginCard], al terminar la app cambia sola de
/// pantalla.
class RegisterCard extends ConsumerStatefulWidget {
  const RegisterCard({super.key, required this.onShowLogin});

  /// El jugador tocó "¿Ya tienes una cuenta?".
  final VoidCallback onShowLogin;

  @override
  ConsumerState<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends ConsumerState<RegisterCard> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _email.text,
          username: _username.text,
          password: _password.text,
          confirmPassword: _confirmPassword.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authControllerProvider);

    return AuthCardFace(
      title: 'Registrarse',
      submitLabel: 'Entrar a la party',
      switchLabel: '¿Ya tienes una cuenta?',
      errorMessage: form.errorMessage,
      isLoading: form.isLoading,
      onSubmit: _submit,
      onSwitch: widget.onShowLogin,
      fields: [
        AuthTextField(
          controller: _username,
          hint: 'Ingrese su nombre de usuario',
          textInputAction: TextInputAction.next,
          enabled: !form.isLoading,
        ),
        AuthTextField(
          controller: _email,
          hint: 'Ingrese su correo',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !form.isLoading,
        ),
        AuthTextField(
          controller: _password,
          hint: 'Contraseña',
          isPassword: true,
          textInputAction: TextInputAction.next,
          enabled: !form.isLoading,
        ),
        AuthTextField(
          controller: _confirmPassword,
          hint: 'Repetir la contraseña',
          isPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          enabled: !form.isLoading,
        ),
      ],
    );
  }
}
