import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/admin_controller.dart';
import 'package:party_tricks/controllers/preferences_controller.dart';
import 'package:party_tricks/models/app_preferences.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/screens/admin/admin_gallery_screen.dart';
import 'package:party_tricks/screens/admin/admin_page.dart';
import 'package:party_tricks/screens/admin/admin_stats_screen.dart';
import 'package:party_tricks/services/admin/admin_providers.dart';
import 'package:party_tricks/services/admin/admin_service.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/widgets/confirm_dialog.dart';
import 'package:party_tricks/widgets/settings_section.dart';

/// Panel de administración y pruebas. Solo se ve en Ajustes si la cuenta
/// tiene su documento en `admins` (decisiones.md, D-27).
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const AdminScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final isAdmin = ref.watch(isAdminProvider);
    if (isAdmin.value != true) {
      return AdminPage(
        title: 'Administración',
        children: [
          if (isAdmin.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            const SettingsSection(
              title: 'Sin acceso',
              children: [Text('Esta cuenta no es administradora.')],
            ),
        ],
      );
    }
    return AdminPage(
      title: 'Administración',
      children: [
        SettingsSection(
          title: 'Ver la app',
          children: [
            SettingsTile(
              label: 'Galería de pantallas',
              icon: Icons.photo_library,
              onTap: () =>
                  Navigator.of(context).push(AdminGalleryScreen.route()),
            ),
            SettingsTile(
              label: 'Estadísticas de la app',
              icon: Icons.insights,
              onTap: () => Navigator.of(context).push(AdminStatsScreen.route()),
            ),
          ],
        ),
        if (profile != null) _EconomySection(profile: profile),
        if (profile != null) _DevSection(profile: profile),
      ],
    );
  }
}

void _show(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Monedas, diamantes y dados extra de la cuenta propia, para probar la
/// tienda y los cofres.
class _EconomySection extends ConsumerWidget {
  const _EconomySection({required this.profile});

  final UserProfile profile;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    try {
      await action();
      if (context.mounted) _show(context, done);
    } on AdminException catch (e) {
      if (context.mounted) _show(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.read(adminControllerProvider);
    return SettingsSection(
      title: 'Economía',
      children: [
        SettingsTile(label: 'Monedas', value: '${profile.coins}'),
        SettingsTile(label: 'Diamantes', value: '${profile.diamonds}'),
        SettingsTile(label: 'Dados extra', value: '${profile.extraDice}'),
        SettingsTile(
          label: '+100 monedas',
          icon: Icons.add_circle,
          onTap: () => _run(
            context,
            () => admin.adjustWallet(coins: 100),
            'Listo: +100 monedas',
          ),
        ),
        SettingsTile(
          label: '+10 diamantes',
          icon: Icons.add_circle,
          onTap: () => _run(
            context,
            () => admin.adjustWallet(diamonds: 10),
            'Listo: +10 diamantes',
          ),
        ),
        SettingsTile(
          label: '+1 dado extra',
          icon: Icons.add_circle,
          onTap: () => _run(
            context,
            () => admin.adjustWallet(extraDice: 1),
            'Listo: +1 dado extra',
          ),
        ),
        SettingsTile(
          label: 'Dejar todo en 0',
          icon: Icons.restart_alt,
          danger: true,
          onTap: () async {
            final ok = await ConfirmDialog.show(
              context,
              title: 'Dejar en 0',
              message: '¿Dejar tus monedas, diamantes y dados extra en 0?',
              confirmLabel: 'Dejar en 0',
            );
            if (ok && context.mounted) {
              await _run(context, admin.resetWallet, 'Cuenta en 0');
            }
          },
        ),
      ],
    );
  }
}

/// Datos para revisar cosas pequeñas: la cuenta, la pantalla y el modo.
class _DevSection extends ConsumerStatefulWidget {
  const _DevSection({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_DevSection> createState() => _DevSectionState();
}

class _DevSectionState extends ConsumerState<_DevSection> {
  Future<void> _copy(String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _show(context, '$label copiado');
  }

  /// Dibuja el borde de cada widget (solo en modo depuración).
  void _toggleBounds(bool value) {
    setState(() => debugPaintSizeEnabled = value);
    WidgetsBinding.instance.performReassemble();
  }

  Future<void> _resetPreferences() async {
    await ref.read(preferencesServiceProvider).save(const AppPreferences());
    ref.invalidate(preferencesControllerProvider);
    if (mounted) _show(context, 'Preferencias reiniciadas');
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final media = MediaQuery.of(context);
    final size = media.size;
    final mode = kReleaseMode
        ? 'Release'
        : kProfileMode
        ? 'Profile'
        : 'Debug';
    return SettingsSection(
      title: 'Desarrollo',
      children: [
        SettingsTile(
          label: 'Mi uid',
          value: profile.uid,
          icon: Icons.copy,
          onTap: () => _copy('uid', profile.uid),
        ),
        SettingsTile(label: 'Correo', value: profile.email),
        SettingsTile(label: 'XP', value: '${profile.experience}'),
        SettingsTile(
          label: 'Pantalla',
          value:
              '${size.width.round()} × ${size.height.round()} dp · '
              '×${media.devicePixelRatio.toStringAsFixed(1)}',
        ),
        SettingsTile(
          label: 'Tamaño de letra',
          value: '×${media.textScaler.scale(1).toStringAsFixed(2)}',
        ),
        SettingsTile(label: 'Modo', value: mode),
        if (kDebugMode)
          SettingsSwitchTile(
            label: 'Ver bordes de widgets',
            value: debugPaintSizeEnabled,
            onChanged: _toggleBounds,
          ),
        SettingsTile(
          label: 'Reiniciar preferencias',
          icon: Icons.restart_alt,
          onTap: _resetPreferences,
        ),
      ],
    );
  }
}
