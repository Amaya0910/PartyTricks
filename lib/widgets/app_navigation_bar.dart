import 'package:flutter/material.dart';
import 'package:party_tricks/models/app_section.dart';

/// Barra de navegación inferior. No conoce Riverpod: recibe la sección
/// seleccionada y avisa cuando el jugador toca otra.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelected;

  // Íconos provisionales: reemplazar por los exportados de Figma.
  static const Map<AppSection, _NavItem> _items = {
    AppSection.shop: _NavItem(
      'Tienda',
      Icons.storefront_outlined,
      Icons.storefront,
    ),
    AppSection.wardrobe: _NavItem(
      'Vestuario',
      Icons.checkroom_outlined,
      Icons.checkroom,
    ),
    AppSection.home: _NavItem(
      'Inicio',
      Icons.home_outlined,
      Icons.home,
    ),
    AppSection.stats: _NavItem(
      'Stats',
      Icons.bar_chart_outlined,
      Icons.bar_chart,
    ),
    AppSection.friends: _NavItem(
      'Amigos',
      Icons.people_outline,
      Icons.people,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selected.index,
      onDestinationSelected: (index) => onSelected(AppSection.values[index]),
      destinations: [
        for (final section in AppSection.values)
          NavigationDestination(
            icon: Icon(_items[section]!.icon),
            selectedIcon: Icon(_items[section]!.selectedIcon),
            label: _items[section]!.label,
          ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}