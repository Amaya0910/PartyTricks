import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/auth/auth_validators.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/auth_card_face.dart';
import 'package:party_tricks/widgets/auth_text_field.dart';

/// Primera vez con Google: falta el nombre de usuario. Al guardarlo se crea
/// el perfil (con su código de amistad) y `AppGate` pasa sola a la app.
class ChooseUsernameScreen extends ConsumerStatefulWidget {
  const ChooseUsernameScreen({super.key});

  @override
  ConsumerState<ChooseUsernameScreen> createState() =>
      _ChooseUsernameScreenState();
}

class _ChooseUsernameScreenState extends ConsumerState<ChooseUsernameScreen> {
  final _username = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .completeProfile(_username.text);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SizedBox(
                height: 360,
                child: AuthCardFace(
                  title: 'Elige tu nombre',
                  submitLabel: 'Entrar a la party',
                  switchLabel: 'Usar otra cuenta',
                  errorMessage: form.errorMessage,
                  isLoading: form.isLoading,
                  onSubmit: _submit,
                  onSwitch: ref.read(authControllerProvider.notifier).signOut,
                  fields: [
                    const Text(
                      'Así te verán los demás jugadores. De '
                      '${AuthValidators.usernameMinLength} a '
                      '${AuthValidators.usernameMaxLength} caracteres: '
                      'letras, números y guion bajo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.authHint),
                    ),
                    AuthTextField(
                      controller: _username,
                      hint: 'Nombre de usuario',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      enabled: !form.isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
