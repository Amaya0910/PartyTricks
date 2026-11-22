// H-08 (OWASP M4): el chat, las invitaciones y los reportes solo revisaban
// algunos campos. Se podía falsificar la vista previa del chat a nombre del
// amigo, firmar una invitación con otro nombre o adjuntar datos sin límite.
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { addDoc, collection, doc, setDoc, writeBatch } from 'firebase/firestore';
import { LEO, TAY, crearEntorno, parDe } from './entorno.mjs';

const PAR = parDe(TAY, LEO);
const MIEMBROS = [LEO, TAY].sort();

// Un mensaje tal como lo arma la app (ChatMessage.toMap).
const mensaje = (extra = {}) => ({
  senderId: TAY,
  text: 'hola, ¿jugamos?',
  sentAt: Date.now(),
  type: 'text',
  ...extra,
});

// Una invitación tal como la arma la app (PartyInvite.toMap).
const invitacion = (extra = {}) => ({
  fromUid: TAY,
  fromName: 'Tay',
  toUid: LEO,
  roomId: '-NsalaDePrueba01',
  roomCode: 'ABCDEF',
  sentAt: Date.now(),
  seen: false,
  ...extra,
});

describe('H-08 · Chat, invitaciones y reportes con campos validados', () => {
  let env;

  before(async () => {
    env = await crearEntorno();
  });

  after(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `friendships/${PAR}`), {
        members: MIEMBROS,
        requestedBy: TAY,
        status: 'accepted',
        createdAt: 1,
      });
      await setDoc(doc(db, 'usernames/tay'), { uid: TAY });
      await setDoc(doc(db, 'usernames/leo'), { uid: LEO });
    });
  });

  const dbDe = (uid) =>
    env.authenticatedContext(uid, { email_verified: true }).firestore();

  // Como FirestoreSocialPaths.addMessage: el mensaje y el resumen del chat
  // van en la misma escritura.
  function enviar(db, datos) {
    const batch = writeBatch(db);
    batch.set(doc(collection(db, `chats/${PAR}/messages`)), datos);
    batch.set(doc(db, `chats/${PAR}`), { members: MIEMBROS, lastMessage: datos }, { merge: true });
    return batch.commit();
  }

  // Ataques: tienen que fallar.

  it('no se puede falsificar la vista previa del chat a nombre del amigo', async () => {
    await assertFails(
      setDoc(
        doc(dbDe(TAY), `chats/${PAR}`),
        {
          members: MIEMBROS,
          lastMessage: mensaje({ senderId: LEO, text: 'ya no quiero ser tu amigo' }),
        },
        { merge: true },
      ),
    );
  });

  it('no se puede marcar el chat como leído a nombre del amigo', async () => {
    await assertFails(
      setDoc(doc(dbDe(TAY), `chats/${PAR}`), { lastReadAt: { [LEO]: Date.now() } }, { merge: true }),
    );
  });

  it('un mensaje no admite campos que la app no usa', async () => {
    await assertFails(
      addDoc(collection(dbDe(TAY), `chats/${PAR}/messages`), mensaje({ adjunto: 'x'.repeat(50000) })),
    );
  });

  it('un mensaje no admite un tipo inventado', async () => {
    await assertFails(
      addDoc(collection(dbDe(TAY), `chats/${PAR}/messages`), mensaje({ type: 'sistema' })),
    );
  });

  it('una invitación tiene que llevar el nombre real de quien invita', async () => {
    await assertFails(
      addDoc(collection(dbDe(TAY), 'invites'), invitacion({ fromName: 'Administrador' })),
    );
  });

  it('una invitación no admite un código de sala inválido', async () => {
    await assertFails(addDoc(collection(dbDe(TAY), 'invites'), invitacion({ roomCode: 'xx' })));
  });

  it('un reporte no admite un motivo inventado ni campos extra', async () => {
    const reporte = {
      reporterUid: TAY,
      reportedUid: LEO,
      reason: 'harassment',
      chatId: PAR,
      createdAt: Date.now(),
    };
    await assertFails(addDoc(collection(dbDe(TAY), 'reports'), { ...reporte, reason: 'inventado' }));
    await assertFails(
      addDoc(collection(dbDe(TAY), 'reports'), { ...reporte, extra: 'x'.repeat(50000) }),
    );
  });

  // Lo que la app sí necesita: tiene que seguir funcionando.

  it('un amigo envía un mensaje como lo hace la app', async () => {
    await assertSucceeds(enviar(dbDe(TAY), mensaje()));
  });

  it('una invitación como la manda la app (aviso, mensaje y resumen)', async () => {
    const db = dbDe(TAY);
    const datos = invitacion();
    const batch = writeBatch(db);
    batch.set(doc(collection(db, 'invites')), datos);
    const aviso = mensaje({
      type: 'invite',
      text: '¡Te invito a mi party! Código ABC-DEF',
      sentAt: datos.sentAt,
      roomId: datos.roomId,
      roomCode: datos.roomCode,
    });
    batch.set(doc(collection(db, `chats/${PAR}/messages`)), aviso);
    batch.set(doc(db, `chats/${PAR}`), { members: MIEMBROS, lastMessage: aviso }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  it('una conversación: los dos escriben y marcan como leído', async () => {
    await assertSucceeds(enviar(dbDe(TAY), mensaje()));
    await assertSucceeds(enviar(dbDe(TAY), mensaje({ text: '¿estás?' })));
    await assertSucceeds(enviar(dbDe(LEO), mensaje({ senderId: LEO, text: '¡sí!' })));
    await assertSucceeds(
      setDoc(doc(dbDe(LEO), `chats/${PAR}`), { lastReadAt: { [LEO]: Date.now() } }, { merge: true }),
    );
    await assertSucceeds(
      setDoc(doc(dbDe(TAY), `chats/${PAR}`), { lastReadAt: { [TAY]: Date.now() } }, { merge: true }),
    );
  });

  it('con el chat ya creado tampoco se puede falsificar la vista previa', async () => {
    await assertSucceeds(enviar(dbDe(LEO), mensaje({ senderId: LEO, text: 'hola' })));
    await assertFails(
      setDoc(
        doc(dbDe(TAY), `chats/${PAR}`),
        { lastMessage: mensaje({ senderId: LEO, text: 'ya no quiero ser tu amigo' }) },
        { merge: true },
      ),
    );
  });

  it('marcar el chat como leído, como la app', async () => {
    await assertSucceeds(
      setDoc(doc(dbDe(TAY), `chats/${PAR}`), { lastReadAt: { [TAY]: Date.now() } }, { merge: true }),
    );
  });

  it('un reporte como lo hace la app', async () => {
    await assertSucceeds(
      addDoc(collection(dbDe(TAY), 'reports'), {
        reporterUid: TAY,
        reportedUid: LEO,
        reason: 'harassment',
        chatId: PAR,
        createdAt: Date.now(),
      }),
    );
  });
});
