'use strict';

// Cloud Functions de Party Tricks: mandan las notificaciones.
//
// - Cuando un amigo escribe (`chats/{chatId}/messages/{id}`) le llega un
//   aviso a quien recibe el mensaje.
// - Cuando un amigo invita a una party (`invites/{id}`) le llega un aviso con
//   los botones Aceptar y Rechazar.
//
// Los códigos de cada celular están en `fcmTokens/{token}` (ver
// firebase_notification_service.dart). Desplegar:
//   firebase deploy --only functions
// (necesita el plan Blaze de Firebase).

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const {
  messageNotice,
  inviteNotice,
  buildMulticast,
  deadTokens,
} = require('./notifications');

admin.initializeApp();
const db = admin.firestore();

/** Los códigos de los celulares de [uid]. */
async function tokensOf(uid) {
  const snap = await db.collection('fcmTokens').where('uid', '==', uid).get();
  return snap.docs.map((doc) => doc.id);
}

/** Manda [notice] a todos los celulares de su destinatario. */
async function deliver(notice) {
  const tokens = await tokensOf(notice.toUid);
  if (tokens.length === 0) return;
  const result = await admin
    .messaging()
    .sendEachForMulticast(buildMulticast(notice, tokens));
  // Los códigos que ya no sirven (app desinstalada...) se borran.
  const dead = deadTokens(tokens, result.responses);
  await Promise.all(dead.map((token) => db.collection('fcmTokens').doc(token).delete()));
  logger.info('Aviso enviado', {
    kind: notice.kind,
    sent: result.successCount,
    failed: result.failureCount,
  });
}

exports.notifyMessage = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const message = event.data && event.data.data();
    if (!message) return;
    const profile = await db.collection('publicProfiles').doc(message.senderId).get();
    const notice = messageNotice({
      chatId: event.params.chatId,
      message,
      senderName: profile.exists ? profile.get('username') : null,
    });
    if (notice) await deliver(notice);
  },
);

exports.notifyInvite = onDocumentCreated('invites/{inviteId}', async (event) => {
  const invite = event.data && event.data.data();
  const notice = inviteNotice({ inviteId: event.params.inviteId, invite });
  if (notice) await deliver(notice);
});
