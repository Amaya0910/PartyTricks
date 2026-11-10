import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:party_tricks/firebase_options.dart';
import 'package:party_tricks/models/notification_payload.dart';
import 'package:party_tricks/services/notifications/local_notifications.dart';

/// Lo que pasa con la app cerrada o en segundo plano. Estas funciones se
/// ejecutan en otro proceso (otro "isolate"), sin pantallas ni Riverpod, por
/// eso son funciones sueltas y llevan `vm:entry-point`.

Future<void> _ensureFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Llega un aviso del servidor con la app cerrada. En Android el aviso trae
/// solo datos y aquí se arma la notificación (con sus botones); en iOS el
/// aviso ya trae su texto y sus botones.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!LocalNotifications.showsRemoteMessages) return;
  final payload = NotificationPayload.tryFromData(message.data);
  if (payload == null) return;
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(settings: LocalNotifications.settings);
  await LocalNotifications.show(plugin, payload);
}

/// El jugador tocó un botón de una notificación que no abre la app:
/// "Rechazar" marca la invitación como rechazada desde aquí mismo.
@pragma('vm:entry-point')
Future<void> notificationBackgroundResponse(
  NotificationResponse response,
) async {
  if (response.actionId != NotificationActions.decline) return;
  final payload = NotificationPayload.tryParse(response.payload);
  final inviteId = payload?.inviteId;
  if (inviteId == null) return;
  try {
    await _ensureFirebase();
    await FirebaseFirestore.instance.collection('invites').doc(inviteId).update(
      {'seen': true, 'declined': true},
    );
  } catch (_) {
    // Si no hay conexión, la invitación sigue pendiente y saldrá en la app.
  }
}
