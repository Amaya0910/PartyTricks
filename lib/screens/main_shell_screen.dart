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
import 'package:party_tricks/widgets/app_usage_tracker.dart';
import 'package:party_tricks/widgets/invite_listener.dart';
import 'package:party_tricks/widgets/public_profile_publisher.dart';

/// Estructura principal: el fondo del juego, la sección activa encima
/// y la barra de navegación abajo.
///
/// No usa SafeArea: cada pantalla decide cómo respetar las zonas seguras,
/// para que el fondo pueda llegar hasta los bordes.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(navigationControllerProvider);

    // Mientras hay sesión iniciada: mide el tiempo y la racha, mantiene el
    // perfil público al día y avisa de las invitaciones a una party.
    return AppUsageTracker(
      child: PublicProfilePublisher(
        child: InviteListener(child: _shell(ref, selected)),
      ),
    );
  }

  Widget _shell(WidgetRef ref, AppSection selected) {
    return Scaffold(
      // El contenido llega hasta el borde inferior, por detrás de la barra.
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo común a todas las secciones; las colinas quedan ancladas
          // abajo.
          Image.asset(
            'assets/images/Fondo_Principal.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          // IndexedStack conserva el estado de cada sección al cambiar de
          // pestaña.
          IndexedStack(
            index: selected.index,
            children: AppSection.values.map(_screenFor).toList(),
          ),
        ],
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
