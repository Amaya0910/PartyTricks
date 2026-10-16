import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/navigation_controller.dart';
import 'package:party_tricks/models/app_section.dart';
import 'package:party_tricks/screens/friends_screen.dart';
import 'package:party_tricks/screens/home_screen.dart';
import 'package:party_tricks/screens/shop_screen.dart';
import 'package:party_tricks/screens/stats_screen.dart';
import 'package:party_tricks/screens/wardrobe_screen.dart';
import 'package:party_tricks/widgets/app_navigation_bar.dart';

/// Estructura principal: la sección activa arriba y la barra de navegación abajo.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(navigationControllerProvider);

    return Scaffold(
      body: SafeArea(
        // IndexedStack conserva el estado de cada sección al cambiar de pestaña.
        child: IndexedStack(
          index: selected.index,
          children: AppSection.values.map(_screenFor).toList(),
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        selected: selected,
        onSelected: ref.read(navigationControllerProvider.notifier).select,
      ),
    );
  }

  // El switch es exhaustivo: si se agrega una sección, Dart avisa que falta aquí.
  Widget _screenFor(AppSection section) => switch (section) {
        AppSection.shop => const ShopScreen(),
        AppSection.wardrobe => const WardrobeScreen(),
        AppSection.home => const HomeScreen(),
        AppSection.stats => const StatsScreen(),
        AppSection.friends => const FriendsScreen(),
      };
}