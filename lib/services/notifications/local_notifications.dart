import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:party_tricks/models/notification_payload.dart';

/// Los botones de una notificación de invitación.
abstract final class NotificationActions {
  static const accept = 'accept';
  static const decline = 'decline';
}

/// Cómo se arman las notificaciones locales. Las usan la app abierta y el
/// proceso que recibe los avisos con la app cerrada.
abstract final class LocalNotifications {
  static const _icon = 'ic_stat_party';
  static const _messageChannel = 'mensajes';
  static const _inviteChannel = 'invitaciones';

  /// La categoría de iOS que lleva los botones Aceptar y Rechazar. El
  /// servidor la manda en el aviso (`category`).
  static const inviteCategory = 'invite';

  static final settings = InitializationSettings(
    android: const AndroidInitializationSettings(_icon),
    iOS: DarwinInitializationSettings(
      // El permiso se pide aparte, cuando el jugador ya inició sesión.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          inviteCategory,
          actions: [
            DarwinNotificationAction.plain(
              NotificationActions.accept,
              'Aceptar',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              NotificationActions.decline,
              'Rechazar',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
      ],
    ),
  );

  /// Los detalles de [payload]: las invitaciones llevan los botones.
  static NotificationDetails detailsOf(NotificationPayload payload) {
    if (!payload.canRespond) {
      return const NotificationDetails(
        android: AndroidNotificationDetails(
          _messageChannel,
          'Mensajes',
          channelDescription: 'Cuando un amigo te escribe',
          importance: Importance.high,
          priority: Priority.high,
          icon: _icon,
        ),
        iOS: DarwinNotificationDetails(),
      );
    }
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _inviteChannel,
        'Invitaciones',
        channelDescription: 'Cuando un amigo te invita a jugar',
        importance: Importance.max,
        priority: Priority.high,
        icon: _icon,
        actions: [
          AndroidNotificationAction(
            NotificationActions.accept,
            'Aceptar',
            // Abre la app para entrar a la sala.
            showsUserInterface: true,
          ),
          AndroidNotificationAction(NotificationActions.decline, 'Rechazar'),
        ],
      ),
      iOS: DarwinNotificationDetails(categoryIdentifier: inviteCategory),
    );
  }

  /// Muestra la notificación de [payload].
  static Future<void> show(
    FlutterLocalNotificationsPlugin plugin,
    NotificationPayload payload,
  ) {
    return plugin.show(
      id: payload.notificationId,
      title: payload.title,
      body: payload.body,
      notificationDetails: detailsOf(payload),
      payload: payload.toJson(),
    );
  }

  /// Solo Android muestra aquí los avisos del servidor: en iOS el aviso ya
  /// trae su texto y sus botones.
  static bool get showsRemoteMessages =>
      defaultTargetPlatform == TargetPlatform.android;
}
