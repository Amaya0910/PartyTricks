import 'package:flutter/material.dart';
import 'package:party_tricks/models/app_section.dart';
import 'package:party_tricks/theme/app_colors.dart';
import 'package:party_tricks/widgets/fx/pressable_scale.dart';

// Ajustes de la animación y del tamaño de la barra.
const double _barHeight = 64;
const double _lift = 16;
const double _activeWidthFactor = 1.3;
const double _activeIconScale = 1.2;
const Duration _animationDuration = Duration(milliseconds: 280);
const Curve _animationCurve = Curves.easeOutCubic;
const double _activeRadius = 18;
const Duration _iconBounceDuration = Duration(milliseconds: 700);

/// Barra de navegación inferior a medida.
///
/// El botón activo se levanta, se agranda y empuja a los demás; su ícono
/// entra con un rebote y los botones se hunden un poco al tocarlos.
/// No conoce Riverpod: recibe la sección seleccionada y avisa cuando
/// el jugador toca otra.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _barHeight + _lift,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sections = AppSection.values;
              final unit =
                  constraints.maxWidth /
                  (sections.length - 1 + _activeWidthFactor);

              var left = 0.0;
              final items = <Widget>[];
              for (final section in sections) {
                final isSelected = section == selected;
                final width = isSelected ? unit * _activeWidthFactor : unit;

                items.add(
                  AnimatedPositioned(
                    key: ValueKey(section),
                    duration: _animationDuration,
                    curve: _animationCurve,
                    left: left,
                    bottom: 0,
                    width: width,
                    height: isSelected ? _barHeight + _lift : _barHeight,
                    child: _NavigationItem(
                      data: _itemData[section]!,
                      isSelected: isSelected,
                      onTap: () => onSelected(section),
                    ),
                  ),
                );
                left += width;
              }

              return Stack(
                children: [
                  // Franja de fondo con sombra hacia arriba: separa la barra
                  // del contenido.
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _barHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.inactiveButton,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pillShadow,
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...items,
                ],
              );
            },
          ),
        ),
        // Relleno para la zona segura inferior (barra de gestos del celular).
        ColoredBox(
          color: AppColors.inactiveButton,
          child: SizedBox(height: bottomInset, width: double.infinity),
        ),
      ],
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: data.label,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.92,
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: _animationCurve,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.activeButton
                : AppColors.inactiveButton,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isSelected ? _activeRadius : 0),
            ),
            // El activo tiene brillo arriba y sombra: se ve levantado.
            // (Con degradado, Flutter ignora `color`: por eso lo repite.)
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Color.alphaBlend(AppColors.gloss, AppColors.activeButton),
                      AppColors.activeButton,
                    ],
                  )
                : null,
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: AppColors.pillShadow,
                      blurRadius: 6,
                      offset: Offset(0, -2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Al quedar activo, el ícono entra con un rebote elástico.
              TweenAnimationBuilder<double>(
                key: ValueKey(isSelected),
                tween: Tween<double>(
                  begin: isSelected ? 0.7 : _activeIconScale,
                  end: isSelected ? _activeIconScale : 1.0,
                ),
                duration: isSelected ? _iconBounceDuration : _animationDuration,
                curve: isSelected ? Curves.elasticOut : _animationCurve,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Icon(
                  data.icon,
                  size: 28,
                  color: AppColors.navigationContent,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.label,
                    style: const TextStyle(
                      color: AppColors.navigationContent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.label, this.icon);

  final String label;
  final IconData icon;
}

// Íconos provisionales: reemplazar por los exportados de Figma.
const Map<AppSection, _NavItemData> _itemData = {
  AppSection.shop: _NavItemData('Tienda', Icons.shopping_cart),
  AppSection.wardrobe: _NavItemData('Vestuario', Icons.checkroom),
  AppSection.home: _NavItemData('Inicio', Icons.sports_esports),
  AppSection.stats: _NavItemData('Stats', Icons.bar_chart),
  AppSection.friends: _NavItemData('Amigos', Icons.people),
};
