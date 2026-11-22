'use strict';

const test = require('node:test');
const assert = require('node:assert');
const {
  shorten,
  recipientOf,
  messageNotice,
  inviteNotice,
  buildMulticast,
  deadTokens,
} = require('../notifications');

test('el destinatario es el otro jugador del chat', () => {
  assert.strictEqual(recipientOf('ana_beto', 'ana'), 'beto');
  assert.strictEqual(recipientOf('ana_beto', 'beto'), 'ana');
});

test('si quien escribe no es del chat, no hay destinatario', () => {
  assert.strictEqual(recipientOf('ana_beto', 'caro'), null);
  assert.strictEqual(recipientOf('raro', 'ana'), null);
});

test('un mensaje avisa a quien lo recibe, con el nombre de quien escribe', () => {
  const notice = messageNotice({
    chatId: 'ana_beto',
    message: { senderId: 'ana', text: 'Hola', type: 'text' },
    senderName: 'Ana',
  });
  assert.strictEqual(notice.toUid, 'beto');
  assert.strictEqual(notice.title, 'Ana');
  assert.strictEqual(notice.body, 'Hola');
  assert.strictEqual(notice.data.kind, 'message');
  assert.strictEqual(notice.data.fromUid, 'ana');
});

test('un mensaje largo se recorta', () => {
  const text = 'a'.repeat(150);
  assert.strictEqual(shorten(text).length, 100);
  assert.ok(shorten(text).endsWith('…'));
});

test('la invitación guardada en el chat no avisa dos veces', () => {
  const notice = messageNotice({
    chatId: 'ana_beto',
    message: { senderId: 'ana', text: '¡Te invito!', type: 'invite' },
    senderName: 'Ana',
  });
  assert.strictEqual(notice, null);
});

test('una invitación lleva lo necesario para aceptarla', () => {
  const notice = inviteNotice({
    inviteId: 'inv1',
    invite: { fromUid: 'ana', fromName: 'Ana', toUid: 'beto', roomId: 'r1', roomCode: 'ABC123' },
  });
  assert.strictEqual(notice.toUid, 'beto');
  assert.strictEqual(notice.kind, 'invite');
  assert.deepStrictEqual(
    [notice.data.inviteId, notice.data.roomCode, notice.data.roomId],
    ['inv1', 'ABC123', 'r1'],
  );
});

test('una invitación sin código no avisa', () => {
  assert.strictEqual(inviteNotice({ inviteId: 'x', invite: { fromUid: 'a', toUid: 'b' } }), null);
});

test('Android recibe solo datos y iOS el aviso con los botones', () => {
  const notice = inviteNotice({
    inviteId: 'inv1',
    invite: { fromUid: 'ana', fromName: 'Ana', toUid: 'beto', roomId: 'r1', roomCode: 'ABC123' },
  });
  const message = buildMulticast(notice, ['t1', 't2']);
  assert.deepStrictEqual(message.tokens, ['t1', 't2']);
  assert.strictEqual(message.notification, undefined);
  assert.strictEqual(message.android.priority, 'high');
  assert.strictEqual(message.apns.payload.aps.category, 'invite');
  assert.strictEqual(JSON.parse(message.apns.payload.payload).inviteId, 'inv1');
  // Los datos de FCM son todos texto.
  for (const value of Object.values(message.data)) assert.strictEqual(typeof value, 'string');
});

test('los mensajes de chat no llevan botones', () => {
  const notice = messageNotice({
    chatId: 'ana_beto',
    message: { senderId: 'ana', text: 'Hola' },
    senderName: 'Ana',
  });
  assert.strictEqual(buildMulticast(notice, ['t']).apns.payload.aps.category, undefined);
});

test('se detectan los códigos que ya no sirven', () => {
  const dead = deadTokens(
    ['a', 'b', 'c'],
    [
      { success: true },
      { success: false, error: { code: 'messaging/registration-token-not-registered' } },
      { success: false, error: { code: 'messaging/internal-error' } },
    ],
  );
  assert.deepStrictEqual(dead, ['b']);
});
