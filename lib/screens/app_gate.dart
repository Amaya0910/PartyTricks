import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/loading_controller.dart';
import 'package:party_tricks/screens/auth_screen.dart';
import 'package:party_tricks/screens/choose_username_screen.dart';
import 'package:party_tricks/screens/loading_screen.dart';
import 'package:party_tricks/screens/main_shell_screen.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';

/// Decide qué pantalla mostrar:
/// carga → (sin sesión) inicio de sesión o registro → (con sesión) la app.
/// Si entró con Google por primera vez, antes elige su nombre de usuario.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(loadingControllerProvider);
    // Se observa desde el inicio para que Firebase ya haya revisado la sesión
    // cuando termine la carga.
    final profile = ref.watch(userProfileProvider);
    final authUser = ref.watch(authUserProvider).value;

    final Widget screen;
    if (!loading.isDone) {
      screen = LoadingScreen(
        key: const ValueKey('loading'),
        progress: loading.progress,
      );
    } else {
      screen = profile.when(
        // La barra ya llegó al final, pero Firebase aún no responde.
        loading: () => LoadingScreen(
          key: const ValueKey('loading'),
          progress: loading.progress,
        ),
        // Sin conexión o con un error: se deja entrar a la pantalla de acceso,
        // que muestra el mensaje cuando el jugador lo intenta.
        error: (_, _) => const AuthScreen(key: ValueKey('auth')),
        data: (user) {
          if (user != null) return const MainShellScreen(key: ValueKey('main'));
          // Con Google no hay registro: si la cuenta aún no tiene perfil,
          // falta el nombre de usuario. (Con correo el perfil se crea al
          // registrarse, así que no se muestra esta pantalla.)
          if (authUser != null && authUser.hasGoogle) {
            return const ChooseUsernameScreen(key: ValueKey('username'));
          }
          return const AuthScreen(key: ValueKey('auth'));
        },
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: screen,
    );
  }
}
