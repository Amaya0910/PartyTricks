// H-04 (OWASP M3/M4): el perfil público aceptaba cualquier dato de su dueño,
// así que un jugador podía mostrarse con el nombre, el código de amistad o
// la XP de otro (suplantación) y agregar campos sin límite.
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc } from 'firebase/firestore';
import { LEO, TAY, crearEntorno } from './entorno.mjs';

// El perfil público tal como lo arma la app (PublicProfile.toMap).
const perfilDeTay = {
  username: 'Tay',
  friendCode: 'TAY123',
  experience: 120,
  photoUrl: null,
  skinTone: 0,
  eyes: 2,
  eyeColor: 0,
  mouth: 1,
  mouthColor: 0,
  avatarColor: 0,
  facePhoto: null,
};

describe('H-04 · El perfil público no se puede falsificar', () => {
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
      await setDoc(doc(db, `users/${TAY}`), {
        username: 'Tay',
        friendCode: 'TAY123',
        experience: 120,
      });
      await setDoc(doc(db, 'usernames/tay'), { uid: TAY });
      await setDoc(doc(db, 'friendCodes/TAY123'), { uid: TAY });
      await setDoc(doc(db, `users/${LEO}`), {
        username: 'Leo',
        friendCode: 'LEO456',
        experience: 40,
      });
      await setDoc(doc(db, 'usernames/leo'), { uid: LEO });
      await setDoc(doc(db, 'friendCodes/LEO456'), { uid: LEO });
    });
  });

  const publicar = (uid, perfil) =>
    setDoc(doc(env.authenticatedContext(uid).firestore(), `publicProfiles/${TAY}`), perfil);

  // Ataques: tienen que fallar.

  it('nadie puede escribir el perfil público de otro', async () => {
    await assertFails(publicar(LEO, perfilDeTay));
  });

  it('no se puede publicar con el nombre de otro jugador', async () => {
    await assertFails(publicar(TAY, { ...perfilDeTay, username: 'Leo' }));
  });

  it('no se puede mostrar el código de amistad de otro jugador', async () => {
    await assertFails(publicar(TAY, { ...perfilDeTay, friendCode: 'LEO456' }));
  });

  it('no se puede mostrar más XP de la que se tiene', async () => {
    await assertFails(publicar(TAY, { ...perfilDeTay, experience: 99999 }));
  });

  it('no se puede poner una foto alojada en un servidor externo', async () => {
    await assertFails(
      publicar(TAY, { ...perfilDeTay, photoUrl: 'https://atacante.example/rastreo.png' }),
    );
  });

  it('no se pueden agregar campos que la app no usa', async () => {
    await assertFails(publicar(TAY, { ...perfilDeTay, notas: 'x'.repeat(50000) }));
  });

  // Lo que la app sí necesita: tiene que seguir funcionando.

  it('el dueño publica su perfil tal como lo arma la app', async () => {
    await assertSucceeds(publicar(TAY, perfilDeTay));
  });
});
