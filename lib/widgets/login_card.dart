import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/widgets/auth_card_face.dart';
import 'package:party_tricks/widgets/auth_text_field.dart';

/// Cara de inicio de sesión. Si sale bien, no navega: la app cambia sola de
/// pantalla cuando aparece el perfil del jugador (ver `AppGate`).
class LoginCard extends ConsumerStatefulWidget {
  const LoginCard({super.key, required this.onShowRegister});

  /// El jugador tocó "¿Aun no te registras?".
  final VoidCallback onShowRegister;

  @override
  ConsumerState<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends ConsumerState<LoginCard> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .signIn(identifier: _identifier.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authControllerProvider);

    return AuthCardFace(
      title: 'Inicio de sesion',
      submitLabel: 'Entrar a la party',
      switchLabel: '¿Aun no te registras?',
      errorMessage: form.errorMessage,
      isLoading: form.isLoading,
      onSubmit: _submit,
      onSwitch: widget.onShowRegister,
      fields: [
        AuthTextField(
          controller: _identifier,
          hint: 'Ingrese su correo o nombre de usuario',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !form.isLoading,
        ),
        AuthTextField(
          controller: _password,
          hint: 'Contraseña',
          isPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          enabled: !form.isLoading,
        ),
      ],
    );
  }
}
