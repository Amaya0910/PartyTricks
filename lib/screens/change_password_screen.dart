import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/account_controller.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/services/auth/auth_validators.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/auth_text_field.dart';
import 'package:party_tricks/widgets/profile_avatar.dart';

/// Cambiar contraseña, como en el mockup: contraseña actual, nueva y
/// confirmación, con el botón Confirmar.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
  }

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(accountControllerProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
            confirmPassword: _confirm.text,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Contraseña cambiada')),
      );
      navigator.pop();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(userProfileProvider).value?.username ?? '';
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Fondo_Principal.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.settingsReload,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Volver'),
                    ),
                    const Spacer(),
                    const ProfileAvatar(size: 36),
                    const SizedBox(width: 8),
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.headerBorder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _Card(
                  children: [
                    _Label('Contraseña actual'),
                    AuthTextField(
                      controller: _current,
                      hint: 'Contraseña actual',
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      enabled: !_saving,
                    ),
                    _Label('Nueva contraseña'),
                    AuthTextField(
                      controller: _new,
                      hint: 'Nueva contraseña',
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      enabled: !_saving,
                    ),
                    _Label('Confirmar nueva contraseña'),
                    AuthTextField(
                      controller: _confirm,
                      hint: 'Repite la nueva contraseña',
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Mínimo ${AuthValidators.passwordMinLength} caracteres, '
                      'con mayúscula, minúscula, número y símbolo.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.settingsReload,
                      ),
                    ),
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
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.settingsOn,
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Confirmar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con cabecera morada "CAMBIAR CONTRASEÑA".
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.friendsBorder, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.settingsAccent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text(
                'CAMBIAR CONTRASEÑA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.authText,
        ),
      ),
    );
  }
}
