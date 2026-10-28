import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/account_controller.dart';
import 'package:party_tricks/controllers/preferences_controller.dart';
import 'package:party_tricks/models/app_preferences.dart';
import 'package:party_tricks/models/legal_document.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/screens/blocked_players_screen.dart';
import 'package:party_tricks/screens/change_password_screen.dart';
import 'package:party_tricks/screens/legal_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/code_digits.dart';
import 'package:party_tricks/widgets/confirm_dialog.dart';
import 'package:party_tricks/widgets/settings_section.dart';
import 'package:party_tricks/widgets/text_fields_dialog.dart';
import 'package:party_tricks/widgets/verify_email_banner.dart';

/// Ajustes, como en el mockup: tu código, la cuenta, las preferencias y más
/// opciones. Se abre al tocar la foto de perfil en Inicio o en Stats.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const SettingsScreen());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final authUser = ref.watch(authUserProvider).value;

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
            child: Column(
              children: [
                const _TopBar(),
                const VerifyEmailBanner(),
                Expanded(
                  child: profile == null
                      ? const Center(child: CircularProgressIndicator())
                      : _Panel(
                          children: [
                            _CodeCard(profile: profile),
                            _AccountSection(
                              profile: profile,
                              hasPassword: authUser?.hasPassword ?? false,
                            ),
                            const _PreferencesSection(),
                            const _MoreSection(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensajes cortos abajo de la pantalla.
void _show(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.settingsReload,
          ),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left),
          label: const Text('Volver'),
        ),
      ),
    );
  }
}

/// Fondo translúcido y desenfocado detrás de las tarjetas.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.settingsPanel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, index) => children[index],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Tu codigo" con Copiar y Recargar.
class _CodeCard extends ConsumerWidget {
  const _CodeCard({required this.profile});

  final UserProfile profile;

  Future<void> _reload(BuildContext context, WidgetRef ref) async {
    final account = ref.read(accountControllerProvider);
    final ok = await ConfirmDialog.show(
      context,
      title: 'Nuevo código',
      message:
          'Tu código actual dejará de servir. Tus amigos de ahora siguen '
          'siendo tus amigos.',
      confirmLabel: 'Cambiar código',
    );
    if (!ok) return;
    try {
      final code = await account.regenerateFriendCode();
      if (context.mounted) _show(context, 'Tu nuevo código es $code');
    } on AuthException catch (error) {
      if (context.mounted) _show(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.friendsBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu código',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          CodeDigits(code: profile.friendCode),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.settingsCopy,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: profile.friendCode),
                    );
                    if (context.mounted) _show(context, 'Código copiado');
                  },
                  child: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.settingsReload,
                  ),
                  onPressed: () => _reload(context, ref),
                  child: const Text('Recargar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.profile, required this.hasPassword});

  final UserProfile profile;

  /// Las cuentas solo de Google no tienen contraseña ni cambian el correo
  /// aquí (se manejan en Google).
  final bool hasPassword;

  Future<void> _changeUsername(BuildContext context, WidgetRef ref) async {
    final account = ref.read(accountControllerProvider);
    final values = await TextFieldsDialog.show(
      context,
      title: 'Nombre',
      message: 'Solo puedes cambiarlo una vez cada 30 días.',
      confirmLabel: 'Guardar',
      fields: [
        DialogField(
          label: 'Nombre de usuario',
          initialValue: profile.username,
          maxLength: 16,
        ),
      ],
    );
    if (values == null) return;
    try {
      await account.changeUsername(values.first);
      if (context.mounted) _show(context, 'Nombre cambiado');
    } on AuthException catch (error) {
      if (context.mounted) _show(context, error.message);
    }
  }

  Future<void> _changeEmail(BuildContext context, WidgetRef ref) async {
    final account = ref.read(accountControllerProvider);
    final values = await TextFieldsDialog.show(
      context,
      title: 'Correo',
      message:
          'Te enviaremos un enlace al correo nuevo. El cambio se hace cuando '
          'lo abras.',
      confirmLabel: 'Enviar enlace',
      fields: const [
        DialogField(
          label: 'Correo nuevo',
          keyboardType: TextInputType.emailAddress,
        ),
        DialogField(label: 'Contraseña actual', obscure: true),
      ],
    );
    if (values == null) return;
    try {
      await account.changeEmail(
        newEmail: values[0],
        currentPassword: values[1],
      );
      if (context.mounted) {
        _show(context, 'Revisa ${values[0].trim()} y abre el enlace.');
      }
    } on AuthException catch (error) {
      if (context.mounted) _show(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'Cuenta',
      children: [
        SettingsTile(
          label: 'Nombre de usuario',
          value: profile.username,
          icon: Icons.edit_square,
          onTap: () => _changeUsername(context, ref),
        ),
        SettingsTile(
          label: 'Correo electrónico',
          value: profile.email,
          icon: hasPassword ? Icons.edit_square : null,
          onTap: hasPassword
              ? () => _changeEmail(context, ref)
              : () => _show(context, 'Tu cuenta usa el correo de Google.'),
        ),
        if (hasPassword)
          SettingsTile(
            label: 'Cambiar contraseña',
            icon: Icons.lock_outline,
            onTap: () =>
                Navigator.of(context).push(ChangePasswordScreen.route()),
          ),
      ],
    );
  }
}

class _PreferencesSection extends ConsumerWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs =
        ref.watch(preferencesControllerProvider).value ??
        const AppPreferences();
    final controller = ref.read(preferencesControllerProvider.notifier);
    return SettingsSection(
      title: 'Preferencias',
      children: [
        SettingsSwitchTile(
          label: 'Notificaciones',
          value: prefs.notifications,
          onChanged: controller.setNotifications,
        ),
        SettingsSwitchTile(
          label: 'Sonido',
          value: prefs.sound,
          onChanged: controller.setSound,
        ),
        SettingsSwitchTile(
          label: 'Efectos de sonido',
          value: prefs.soundEffects,
          onChanged: controller.setSoundEffects,
        ),
        SettingsTile(
          label: 'Idioma',
          value: 'Español',
          icon: Icons.arrow_forward,
          onTap: () => _show(context, 'Por ahora el juego está en español.'),
        ),
      ],
    );
  }
}

class _MoreSection extends ConsumerWidget {
  const _MoreSection();

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final account = ref.read(accountControllerProvider);
    final navigator = Navigator.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: 'Cerrar sesión',
      message: '¿Quieres cerrar sesión en este celular?',
      confirmLabel: 'Cerrar sesión',
    );
    if (!ok) return;
    // Primero se cierra Ajustes; AppGate muestra la pantalla de acceso.
    navigator.popUntil((route) => route.isFirst);
    await account.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(Route<void> route) => Navigator.of(context).push(route);
    return SettingsSection(
      title: 'Más opciones',
      children: [
        for (final document in LegalDocument.values)
          SettingsTile(
            label: document.title,
            icon: Icons.arrow_forward,
            onTap: () => open(LegalScreen.route(document)),
          ),
        SettingsTile(
          label: 'Jugadores bloqueados',
          icon: Icons.arrow_forward,
          onTap: () => open(BlockedPlayersScreen.route()),
        ),
        SettingsTile(
          label: 'Cerrar sesión',
          icon: Icons.logout,
          danger: true,
          onTap: () => _signOut(context, ref),
        ),
      ],
    );
  }
}
