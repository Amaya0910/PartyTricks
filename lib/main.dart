import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:party_tricks/controllers/preferences_controller.dart';
import 'package:party_tricks/firebase_options.dart';
import 'package:party_tricks/navigation/root_navigator.dart';
import 'package:party_tricks/services/feedback/haptics.dart';
import 'package:party_tricks/services/notifications/notification_background.dart';
import 'package:party_tricks/screens/app_gate.dart';
import 'package:party_tricks/services/release_logging.dart';
import 'package:party_tricks/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // En release no se escribe nada en la consola (H-09).
  silenceDebugLogsInRelease();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Los avisos que llegan con la app cerrada se atienden en otro proceso.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: PartyTricksApp()));
}

class PartyTricksApp extends ConsumerWidget {
  const PartyTricksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La vibración llega a toda la app (diálogos incluidos) desde aquí.
    return HapticsScope(
      haptics: ref.watch(hapticsProvider),
      child: MaterialApp(
        title: 'Party Tricks',
        navigatorKey: rootNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppGate(),
      ),
    );
  }
}
