import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_tricks/services/notifications/firebase_notification_service.dart';
import 'package:party_tricks/services/notifications/notification_service.dart';

/// Las notificaciones de la app. En las pruebas se cambia por una falsa.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => FirebaseNotificationService(),
);
