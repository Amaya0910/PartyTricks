'use strict';

// Arma los avisos que se mandan a los celulares. Son funciones puras (sin
// Firebase) para poder probarlas con `npm test`.

const MAX_BODY = 100;

/** Recorta el texto de un mensaje para que quepa en la notificación. */
function shorten(text) {
  const clean = String(text || '').trim();
  return clean.length > MAX_BODY ? clean.slice(0, MAX_BODY - 1) + '…' : clean;
}

/** El otro jugador de un chat: el id es "uidA_uidB" (ver pair_id.dart). */
function recipientOf(chatId, senderId) {
  const members = String(chatId).split('_');
  if (members.length !== 2 || !members.includes(senderId)) return null;
  return members.find((uid) => uid !== senderId) || null;
}

/**
 * El aviso de un mensaje nuevo. Las invitaciones también se guardan como
 * mensaje del chat, pero su aviso sale aparte (con los botones), así que
 * aquí se saltan.
 */
function messageNotice({ chatId, message, senderName }) {
  if (!message || message.type === 'invite') return null;
  const recipient = recipientOf(chatId, message.senderId);
  if (!recipient) return null;
  const name = senderName || 'Un amigo';
  return {
    toUid: recipient,
    kind: 'message',
    title: name,
    body: shorten(message.text),
    data: {
      kind: 'message',
      fromUid: message.senderId,
      fromName: name,
      body: shorten(message.text),
    },
  };
}

/** El aviso de una invitación a una party. */
function inviteNotice({ inviteId, invite }) {
  if (!invite || !invite.toUid || !invite.fromUid || !invite.roomCode) {
    return null;
  }
  const name = invite.fromName || 'Un amigo';
  const body = `${name} te invitó a su party`;
  return {
    toUid: invite.toUid,
    kind: 'invite',
    title: `¡${name} te invitó a jugar!`,
    body,
    data: {
      kind: 'invite',
      inviteId,
      fromUid: invite.fromUid,
      fromName: name,
      body,
      roomId: invite.roomId || '',
      roomCode: invite.roomCode,
    },
  };
}

/**
 * El mensaje de Firebase Cloud Messaging para [tokens].
 *
 * - Android: solo datos (sin `notification`), para que la app arme la
 *   notificación con sus botones Aceptar y Rechazar aunque esté cerrada.
 * - iOS: el aviso trae su texto y la categoría `invite` (los botones). El
 *   campo `payload` es lo que lee flutter_local_notifications al tocarlo.
 */
function buildMulticast(notice, tokens) {
  const aps = {
    alert: { title: notice.title, body: notice.body },
    sound: 'default',
  };
  if (notice.kind === 'invite') aps.category = 'invite';
  return {
    tokens,
    data: notice.data,
    android: { priority: 'high' },
    apns: {
      headers: { 'apns-priority': '10' },
      payload: { aps, payload: JSON.stringify(notice.data) },
    },
  };
}

/** Errores de FCM que significan "este código ya no sirve". */
const DEAD_TOKEN_ERRORS = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/** Los códigos de [tokens] que FCM rechazó por inválidos, según [responses]. */
function deadTokens(tokens, responses) {
  const dead = [];
  responses.forEach((response, index) => {
    if (!response.success && response.error && DEAD_TOKEN_ERRORS.has(response.error.code)) {
      dead.push(tokens[index]);
    }
  });
  return dead;
}

module.exports = {
  shorten,
  recipientOf,
  messageNotice,
  inviteNotice,
  buildMulticast,
  deadTokens,
};
