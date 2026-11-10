import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/notification_payload.dart';
import 'package:party_tricks/services/notifications/local_notifications.dart';

const _invite = NotificationPayload(
  kind: NotificationKind.invite,
  fromUid: 'ana',
  fromName: 'Ana',
  body: 'Ana te invitó a su party',
  inviteId: 'inv1',
  roomId: 'room1',
  roomCode: 'ABC123',
);

const _message = NotificationPayload(
  kind: NotificationKind.message,
  fromUid: 'ana',
  fromName: 'Ana',
  body: 'Hola',
);

void main() {
  group('los datos de una notificación', () {
    test('ida y vuelta por JSON, sin perder nada', () {
      final back = NotificationPayload.tryParse(_invite.toJson())!;
      expect(back.kind, NotificationKind.invite);
      expect(back.fromUid, 'ana');
      expect(back.inviteId, 'inv1');
      expect(back.roomId, 'room1');
      expect(back.roomCode, 'ABC123');
      expect(back.body, 'Ana te invitó a su party');
    });

    test('los datos de FCM son todos texto', () {
      for (final value in _invite.toData().values) {
        expect(value, isA<String>());
      }
      expect(_message.toData().containsKey('inviteId'), isFalse);
    });

    test('se entienden los datos que manda el servidor', () {
      final payload = NotificationPayload.tryFromData({
        'kind': 'invite',
        'fromUid': 'ana',
        'fromName': 'Ana',
        'body': 'hola',
        'inviteId': 'inv1',
        'roomCode': 'ABC123',
        'roomId': '',
      });
      expect(payload, isNotNull);
      expect(payload!.canRespond, isTrue);
      // Un campo vacío es como si no estuviera.
      expect(payload.roomId, isNull);
    });

    test('un aviso raro no rompe nada: se ignora', () {
      expect(NotificationPayload.tryFromData({}), isNull);
      expect(NotificationPayload.tryFromData({'kind': 'otro'}), isNull);
      expect(
        NotificationPayload.tryFromData({
          'kind': 'message',
          'fromUid': '',
          'fromName': 'x',
          'body': 'y',
        }),
        isNull,
      );
      expect(NotificationPayload.tryParse('no es json'), isNull);
      expect(NotificationPayload.tryParse(null), isNull);
      expect(NotificationPayload.tryParse('[1,2]'), isNull);
    });

    test('solo una invitación completa se puede aceptar o rechazar', () {
      expect(_invite.canRespond, isTrue);
      expect(_message.canRespond, isFalse);
      const noCode = NotificationPayload(
        kind: NotificationKind.invite,
        fromUid: 'ana',
        fromName: 'Ana',
        body: 'x',
        inviteId: 'inv1',
      );
      expect(noCode.canRespond, isFalse);
    });

    test('los mensajes del mismo amigo se reemplazan; las invitaciones no', () {
      const second = NotificationPayload(
        kind: NotificationKind.message,
        fromUid: 'ana',
        fromName: 'Ana',
        body: 'Otro',
      );
      expect(second.notificationId, _message.notificationId);
      expect(_invite.notificationId, isNot(_message.notificationId));
      expect(_invite.notificationId, isNonNegative);
    });
  });

  group('cómo se muestran', () {
    test('la invitación lleva los botones Aceptar y Rechazar', () {
      final android = LocalNotifications.detailsOf(_invite).android!;
      expect(android.actions!.map((a) => a.id), [
        NotificationActions.accept,
        NotificationActions.decline,
      ]);
      // Aceptar abre la app (para entrar a la sala); Rechazar no.
      expect(android.actions![0].showsUserInterface, isTrue);
      expect(android.actions![1].showsUserInterface, isFalse);
      expect(
        LocalNotifications.detailsOf(_invite).iOS!.categoryIdentifier,
        LocalNotifications.inviteCategory,
      );
    });

    test('un mensaje no lleva botones', () {
      final details = LocalNotifications.detailsOf(_message);
      expect(details.android!.actions, isNull);
      expect(details.iOS!.categoryIdentifier, isNull);
    });
  });

  group('el servidor y las reglas', () {
    test('la categoría de iOS es la misma que manda la Cloud Function', () {
      final js = File('functions/notifications.js').readAsStringSync();
      expect(
        js,
        contains("aps.category = '${LocalNotifications.inviteCategory}'"),
      );
    });

    test('los datos que manda la función son los que lee la app', () {
      final js = File('functions/notifications.js').readAsStringSync();
      for (final key in [
        'kind',
        'fromUid',
        'fromName',
        'body',
        'inviteId',
        'roomId',
        'roomCode',
      ]) {
        expect(js, contains(key), reason: key);
      }
    });

    test('las reglas dejan guardar el código del celular y rechazar', () {
      final rules = File('firestore.rules').readAsStringSync();
      expect(rules, contains('match /fcmTokens/{token}'));
      expect(rules, contains("hasOnly(['seen', 'declined'])"));
    });

    test(
      'el rechazo desde la notificación usa los campos que permiten las reglas',
      () {
        final background = File(
          'lib/services/notifications/notification_background.dart',
        ).readAsStringSync();
        expect(background, contains("'seen': true"));
        expect(background, contains("'declined': true"));
      },
    );
  });
}
