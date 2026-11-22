import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:party_tricks/models/notification_payload.dart';
import 'package:party_tricks/services/notifications/local_notifications.dart';
import 'package:party_tricks/services/notifications/notification_background.dart';
import 'package:party_tricks/services/notifications/notification_service.dart';

/// Las notificaciones reales: Firebase Cloud Messaging recibe los avisos del
/// servidor (una Cloud Function los manda cuando llega un mensaje o una
/// invitación) y `flutter_local_notifications` los muestra con sus botones.
///
/// Cada celular se registra en `fcmTokens/{token}` con el uid de su dueño,
/// para que el servidor sepa a dónde mandar los avisos de cada jugador.
///
/// Se usan `getToken`, `onTokenRefresh` y `deleteToken` aunque aparezcan como
/// "deprecados": la Cloud Function manda con el código FCM de siempre
/// (Firebase Admin), no con el nuevo identificador de instalación.
class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _plugin;

  final StreamController<NotificationEvent> _events =
      StreamController<NotificationEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _pluginReady = false;
  String? _token;

  @override
  Stream<NotificationEvent> get events => _events.stream;

  @override
  Future<void> start(
    String uid, {
    required bool Function(NotificationPayload payload) shouldShow,
  }) async {
    await _initPlugin();
    await _requestPermission();
    // ignore: deprecated_member_use
    await _register(uid, await _messaging.getToken());

    await _cancelSubscriptions();
    _subscriptions
      // ignore: deprecated_member_use
      ..add(_messaging.onTokenRefresh.listen((token) => _register(uid, token)))
      // Con la app abierta el sistema no muestra los avisos: se muestran aquí.
      ..add(
        FirebaseMessaging.onMessage.listen((message) {
          final payload = NotificationPayload.tryFromData(message.data);
          if (payload == null || !shouldShow(payload)) return;
          LocalNotifications.show(_plugin, payload);
        }),
      )
      // iOS: tocar el aviso del sistema con la app en segundo plano.
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_openedFromPush));

    // La notificación que abrió la app si estaba cerrada.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      _onResponse(response);
    } else {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _openedFromPush(initial);
    }
  }

  @override
  Future<void> stop(String uid) async {
    await _cancelSubscriptions();
    final token = _token;
    _token = null;
    try {
      if (token != null) {
        await _firestore.collection('fcmTokens').doc(token).delete();
      }
      // ignore: deprecated_member_use
      await _messaging.deleteToken();
    } catch (_) {
      // Sin conexión: el servidor borra los códigos viejos cuando falla un
      // envío.
    }
  }

  Future<void> _initPlugin() async {
    if (_pluginReady) return;
    await _plugin.initialize(
      settings: LocalNotifications.settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationBackgroundResponse,
    );
    _pluginReady = true;
  }

  Future<void> _requestPermission() async {
    // Android 13 o más pide permiso para mostrar notificaciones.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _messaging.requestPermission();
  }

  Future<void> _register(String uid, String? token) async {
    if (token == null) return;
    _token = token;
    await _firestore.collection('fcmTokens').doc(token).set({
      'uid': uid,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _cancelSubscriptions() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _openedFromPush(RemoteMessage message) {
    final payload = NotificationPayload.tryFromData(message.data);
    if (payload != null) {
      _events.add(NotificationEvent(payload, NotificationReply.open));
    }
  }

  void _onResponse(NotificationResponse response) {
    final payload = NotificationPayload.tryParse(response.payload);
    if (payload == null) return;
    final reply = switch (response.actionId) {
      NotificationActions.accept => NotificationReply.accept,
      NotificationActions.decline => NotificationReply.decline,
      _ => NotificationReply.open,
    };
    _events.add(NotificationEvent(payload, reply));
  }
}
