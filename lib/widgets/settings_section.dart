import 'package:flutter/material.dart';
import 'package:party_tricks/theme/app_colors.dart';

/// Tarjeta de Ajustes: cabecera morada con el [title] y las filas debajo,
/// como en el mockup ("Cuenta", "Preferencias", "Más opciones").
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: AppColors.friendsBorder, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.settingsAccent,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    children[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de Ajustes: etiqueta a la izquierda, valor opcional y un ícono o
/// interruptor a la derecha.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String label;

  /// Texto a la derecha (por ejemplo, el nombre de usuario).
  final String? value;

  /// Ícono a la derecha (editar, flecha...). Se ignora si hay [trailing].
  final IconData? icon;

  /// Widget a la derecha (por ejemplo, un interruptor).
  final Widget? trailing;
  final VoidCallback? onTap;

  /// En rojo (Cerrar sesión).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.settingsDanger : AppColors.authText;
    final value = this.value;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.settingsRowBorder, width: 2),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: value == null
                    ? const SizedBox.shrink()
                    : Text(
                        value,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.authText,
                        ),
                      ),
              ),
              if (trailing != null)
                trailing!
              else if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 22, color: AppColors.settingsReload),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila con interruptor (Notificaciones, Sonido...).
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      label: label,
      onTap: () => onChanged(!value),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.settingsOn,
      ),
    );
  }
}
