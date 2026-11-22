import 'package:party_tricks/models/notification_payload.dart';

/// Qué hizo el jugador con una notificación.
enum NotificationReply {
  /// La tocó (sin elegir un botón).
  open,

  /// Tocó "Aceptar" en una invitación.
  accept,

  /// Tocó "Rechazar" en una invitación.
  decline,
}

/// Algo que el jugador hizo con una notificación.
class NotificationEvent {
  const NotificationEvent(this.payload, this.reply);

  final NotificationPayload payload;
  final NotificationReply reply;
}

/// Notificaciones: avisan cuando un amigo te escribe o te invita a jugar, y
/// las invitaciones se pueden aceptar o rechazar sin abrir la app. La
/// versión real usa Firebase Cloud Messaging y notificaciones locales; en
/// las pruebas se cambia por una falsa.
abstract class NotificationService {
  /// Lo que el jugador hace con las notificaciones (tocarlas, aceptar o
  /// rechazar). Incluye la que abrió la app si estaba cerrada.
  Stream<NotificationEvent> get events;

  /// Empieza a avisarle a [uid]: pide permiso, registra este celular para
  /// recibir avisos y muestra las notificaciones que lleguen con la app
  /// abierta cuando [shouldShow] lo permita.
  Future<void> start(
    String uid, {
    required bool Function(NotificationPayload payload) shouldShow,
  });

  /// Deja de avisarle a [uid] en este celular (cerró sesión o apagó las
  /// notificaciones).
  Future<void> stop(String uid);
}
