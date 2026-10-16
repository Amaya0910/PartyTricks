import 'package:flutter/material.dart';
import 'package:party_tricks/models/app_section.dart';
import 'package:party_tricks/theme/app_colors.dart';

// Ajustes de la animación y del tamaño de la barra.
const double _barHeight = 64;
const double _lift = 16;
const double _activeWidthFactor = 1.3;
const double _activeIconScale = 1.2;
const Duration _animationDuration = Duration(milliseconds: 280);
const Curve _animationCurve = Curves.easeOutCubic;

/// Barra de navegación inferior a medida.
///
/// El botón activo se levanta, se agranda y empuja a los demás.
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
              final unit = constraints.maxWidth /
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

              return Stack(children: items);
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: _animationCurve,
          alignment: Alignment.center,
          color: isSelected ? AppColors.activeButton : AppColors.inactiveButton,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? _activeIconScale : 1.0,
                duration: _animationDuration,
                curve: _animationCurve,
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