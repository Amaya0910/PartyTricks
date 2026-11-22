// H-13 (OWASP M3): las reglas no exigían correo verificado para las funciones
// sociales. Una cuenta creada con un correo ajeno podía pedir amistad, chatear
// e invitar a otros jugadores. Ahora esas escrituras piden el claim
// `email_verified` del token (las cuentas de Google ya lo traen en true).
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, addDoc, collection } from 'firebase/firestore';
import { LEO, TAY, crearEntorno, parDe } from './entorno.mjs';

const PAR = parDe(TAY, LEO);
const MIEMBROS = [LEO, TAY].sort();

const mensaje = () => ({
  senderId: TAY,
  text: 'hola, ¿jugamos?',
  sentAt: Date.now(),
  type: 'text',
});

const invitacion = () => ({
  fromUid: TAY,
  fromName: 'Tay',
  toUid: LEO,
  roomId: '-NsalaDePrueba01',
  roomCode: 'ABCDEF',
  sentAt: Date.now(),
  seen: false,
});

describe('H-13 · Correo verificado para amigos, chat e invitaciones', () => {
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
        requestedBy: LEO,
        status: 'pending',
        createdAt: 1,
      });
      await setDoc(doc(db, 'usernames/tay'), { uid: TAY });
    });
  });

  const verificado = (uid) =>
    env.authenticatedContext(uid, { email_verified: true }).firestore();
  const sinVerificar = (uid) =>
    env.authenticatedContext(uid, { email_verified: false }).firestore();
  const sinClaim = (uid) => env.authenticatedContext(uid).firestore();

  const hacerAmigos = () =>
    env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), `friendships/${PAR}`), { status: 'accepted' }),
    );

  describe('ataques: cuenta sin verificar', () => {
    it('no puede pedir amistad', async () => {
      await env.withSecurityRulesDisabled((ctx) =>
        import('firebase/firestore').then(({ deleteDoc }) =>
          deleteDoc(doc(ctx.firestore(), `friendships/${PAR}`)),
        ),
      );
      const nueva = {
        members: MIEMBROS,
        requestedBy: TAY,
        status: 'pending',
        createdAt: Date.now(),
      };
      await assertFails(setDoc(doc(sinVerificar(TAY), `friendships/${PAR}`), nueva));
      await assertFails(setDoc(doc(sinClaim(TAY), `friendships/${PAR}`), nueva));
    });

    it('no puede aceptar una solicitud', async () => {
      await assertFails(
        updateDoc(doc(sinVerificar(TAY), `friendships/${PAR}`), { status: 'accepted' }),
      );
    });

    it('no puede escribir mensajes aunque ya sea amigo', async () => {
      await hacerAmigos();
      await assertFails(
        addDoc(collection(sinVerificar(TAY), `chats/${PAR}/messages`), mensaje()),
      );
      await assertFails(
        addDoc(collection(sinClaim(TAY), `chats/${PAR}/messages`), mensaje()),
      );
    });

    it('no puede actualizar el resumen del chat', async () => {
      await hacerAmigos();
      await assertFails(
        setDoc(doc(sinVerificar(TAY), `chats/${PAR}`), {
          members: MIEMBROS,
          lastMessage: mensaje(),
        }),
      );
    });

    it('no puede invitar a una party', async () => {
      await hacerAmigos();
      await assertFails(addDoc(collection(sinVerificar(TAY), 'invites'), invitacion()));
    });
  });

  describe('uso normal: cuenta verificada', () => {
    it('acepta una solicitud', async () => {
      await assertSucceeds(
        updateDoc(doc(verificado(TAY), `friendships/${PAR}`), { status: 'accepted' }),
      );
    });

    it('escribe mensajes e invita a un amigo', async () => {
      await hacerAmigos();
      await assertSucceeds(
        addDoc(collection(verificado(TAY), `chats/${PAR}/messages`), mensaje()),
      );
      await assertSucceeds(
        setDoc(doc(verificado(TAY), `chats/${PAR}`), {
          members: MIEMBROS,
          lastMessage: mensaje(),
        }),
      );
      await assertSucceeds(addDoc(collection(verificado(TAY), 'invites'), invitacion()));
    });
  });

  describe('lo que no cambia', () => {
    it('una cuenta sin verificar puede rechazar una solicitud y bloquear', async () => {
      await assertSucceeds(
        import('firebase/firestore').then(({ deleteDoc }) =>
          deleteDoc(doc(sinVerificar(TAY), `friendships/${PAR}`)),
        ),
      );
      await assertSucceeds(
        setDoc(doc(sinVerificar(TAY), `blocks/${TAY}_${LEO}`), {
          blocker: TAY,
          blocked: LEO,
        }),
      );
    });
  });
});
