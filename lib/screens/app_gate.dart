import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/controllers/loading_controller.dart';
import 'package:party_tricks/screens/loading_screen.dart';
import 'package:party_tricks/screens/main_shell_screen.dart';

/// Muestra la pantalla de carga hasta que termine y luego la app.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(loadingControllerProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: loading.isDone
          ? const MainShellScreen(key: ValueKey('main'))
          : LoadingScreen(
              key: const ValueKey('loading'),
              progress: loading.progress,
            ),
    );
  }
}