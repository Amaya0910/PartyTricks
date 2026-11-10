import 'dart:convert';

/// Qué avisa una notificación.
enum NotificationKind {
  /// Un amigo te escribió.
  message,

  /// Un amigo te invitó a su party: se puede aceptar o rechazar desde la
  /// notificación.
  invite,
}

/// Lo que lleva una notificación: de quién es, qué dice y, si es una
/// invitación, a qué sala. Viaja por Firebase Cloud Messaging como datos de
/// texto ([tryFromData]) y dentro de la notificación local como JSON
/// ([toJson]).
class NotificationPayload {
  const NotificationPayload({
    required this.kind,
    required this.fromUid,
    required this.fromName,
    required this.body,
    this.inviteId,
    this.roomId,
    this.roomCode,
  });

  final NotificationKind kind;
  final String fromUid;

  /// Nombre de quien escribe o invita.
  final String fromName;

  /// El texto del mensaje, o el aviso de la invitación.
  final String body;

  /// Solo en invitaciones: la invitación (`invites/{id}`) y su sala.
  final String? inviteId;
  final String? roomId;
  final String? roomCode;

  bool get isInvite => kind == NotificationKind.invite;

  /// Una invitación solo se puede aceptar o rechazar si trae todo lo que hace
  /// falta para entrar a la sala.
  bool get canRespond => isInvite && inviteId != null && roomCode != null;

  String get title => isInvite ? '¡$fromName te invitó a jugar!' : fromName;

  /// Número de la notificación: los mensajes del mismo amigo se reemplazan
  /// entre sí y cada invitación tiene la suya.
  int get notificationId =>
      (isInvite ? 'invite:${inviteId ?? fromUid}' : 'chat:$fromUid').hashCode &
      0x7fffffff;

  /// Los datos de texto que manda el servidor (todo son cadenas).
  Map<String, String> toData() => {
    'kind': kind.name,
    'fromUid': fromUid,
    'fromName': fromName,
    'body': body,
    'inviteId': ?inviteId,
    'roomId': ?roomId,
    'roomCode': ?roomCode,
  };

  String toJson() => jsonEncode(toData());

  /// Null si faltan datos para mostrarla (un mensaje raro no rompe nada).
  static NotificationPayload? tryFromData(Map<String, dynamic> data) {
    final kind = switch (data['kind']) {
      'message' => NotificationKind.message,
      'invite' => NotificationKind.invite,
      _ => null,
    };
    final fromUid = data['fromUid'];
    final fromName = data['fromName'];
    final body = data['body'];
    if (kind == null ||
        fromUid is! String ||
        fromUid.isEmpty ||
        fromName is! String ||
        body is! String) {
      return null;
    }
    String? text(String key) {
      final value = data[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return NotificationPayload(
      kind: kind,
      fromUid: fromUid,
      fromName: fromName,
      body: body,
      inviteId: text('inviteId'),
      roomId: text('roomId'),
      roomCode: text('roomCode'),
    );
  }

  /// Lo contrario de [toJson]. Null si no se entiende.
  static NotificationPayload? tryParse(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final data = jsonDecode(json);
      return data is Map<String, dynamic> ? tryFromData(data) : null;
    } catch (_) {
      return null;
    }
  }
}
