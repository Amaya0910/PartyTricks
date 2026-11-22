// H-01 (OWASP M6/M3): la reserva del nombre de usuario guardaba el correo y
// se podía leer sin iniciar sesión.
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { deleteField, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { ANA, LEO, TAY, crearEntorno } from './entorno.mjs';

describe('H-01 · La reserva del nombre no expone el correo', () => {
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
      // Reserva vieja: todavía guarda el correo (así quedaron las cuentas
      // creadas antes de la corrección).
      await setDoc(doc(db, 'usernames/tay'), { uid: TAY, email: 'tay@correo.test' });
      // Reserva nueva: solo el uid.
      await setDoc(doc(db, 'usernames/leo'), { uid: LEO });
    });
  });

  // Ataques: tienen que fallar.

  it('sin sesión no se puede leer la reserva de un nombre', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'usernames/tay')));
  });

  it('otro jugador no puede leer una reserva que todavía tiene el correo', async () => {
    const db = env.authenticatedContext(LEO).firestore();
    await assertFails(getDoc(doc(db, 'usernames/tay')));
  });

  it('no se puede crear una reserva que guarde el correo', async () => {
    const db = env.authenticatedContext(ANA).firestore();
    await assertFails(
      setDoc(doc(db, 'usernames/ana'), { uid: ANA, email: 'ana@correo.test' }),
    );
  });

  it('nadie puede volver a guardar el correo en su reserva', async () => {
    const db = env.authenticatedContext(LEO).firestore();
    await assertFails(updateDoc(doc(db, 'usernames/leo'), { email: 'leo@correo.test' }));
  });

  // Lo que la app sí necesita: tiene que seguir funcionando.

  it('al registrarse se crea la reserva solo con el uid', async () => {
    const db = env.authenticatedContext(ANA).firestore();
    await assertSucceeds(setDoc(doc(db, 'usernames/ana'), { uid: ANA }));
  });

  it('con sesión se puede saber si un nombre está libre o tomado', async () => {
    const db = env.authenticatedContext(ANA).firestore();
    await assertSucceeds(getDoc(doc(db, 'usernames/leo')));
    await assertSucceeds(getDoc(doc(db, 'usernames/libre')));
  });

  it('el dueño puede leer su reserva vieja y quitarle el correo', async () => {
    const db = env.authenticatedContext(TAY).firestore();
    await assertSucceeds(getDoc(doc(db, 'usernames/tay')));
    await assertSucceeds(updateDoc(doc(db, 'usernames/tay'), { email: deleteField() }));
  });
});
