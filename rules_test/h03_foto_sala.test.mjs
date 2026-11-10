// H-03 (OWASP M4/M5): la foto de un jugador en la sala (photoUrl) aceptaba
// cualquier texto, así que los demás celulares descargaban una URL elegida
// por otro jugador (por ejemplo, un servidor que registra su IP).
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { ref, runTransaction, set } from 'firebase/database';
import { LEO, TAY, crearEntorno } from './entorno.mjs';

const SALA = 'sala1';

function jugador(nombre, extra = {}) {
  return { username: nombre, joinedAt: Date.now(), connected: true, ...extra };
}

describe('H-03 · La foto de un jugador en la sala solo puede ser de Google y por HTTPS', () => {
  let env;

  before(async () => {
    env = await crearEntorno();
  });

  after(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearDatabase();
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.database();
      await set(ref(db, `roomCodes/ABCDEF`), SALA);
      await set(ref(db, `rooms/${SALA}`), {
        meta: {
          code: 'ABCDEF',
          isPublic: true,
          hostUid: TAY,
          maxPlayers: 6,
          rounds: 10,
          status: 'waiting',
          lobbyEndsAt: Date.now() + 90000,
        },
        players: { [TAY]: jugador('Tay') },
      });
    });
  });

  // Ataques: tienen que fallar.

  it('no se puede poner como foto una URL de un servidor externo', async () => {
    const db = env.authenticatedContext(LEO).database();
    await assertFails(
      set(
        ref(db, `rooms/${SALA}/players/${LEO}`),
        jugador('Leo', { photoUrl: 'https://atacante.example/rastreo.png?sala=sala1' }),
      ),
    );
  });

  it('no se puede poner como foto una URL por http (sin cifrar)', async () => {
    const db = env.authenticatedContext(LEO).database();
    await assertFails(
      set(
        ref(db, `rooms/${SALA}/players/${LEO}`),
        jugador('Leo', { photoUrl: 'http://lh3.googleusercontent.com/a/foto' }),
      ),
    );
  });

  // Lo que la app sí necesita: tiene que seguir funcionando.

  it('un jugador entra a la sala como lo hace la app (sin foto)', async () => {
    const db = env.authenticatedContext(LEO).database();
    await assertSucceeds(set(ref(db, `rooms/${SALA}/players/${LEO}`), jugador('Leo')));
  });

  it('entrar con la transacción de la app sigue funcionando', async () => {
    const db = env.authenticatedContext(LEO).database();
    await assertSucceeds(
      runTransaction(ref(db, `rooms/${SALA}/players`), (actuales) => ({
        ...actuales,
        [LEO]: jugador('Leo'),
      })),
    );
  });

  it('se acepta una foto de una cuenta de Google por HTTPS', async () => {
    const db = env.authenticatedContext(LEO).database();
    await assertSucceeds(
      set(
        ref(db, `rooms/${SALA}/players/${LEO}`),
        jugador('Leo', { photoUrl: 'https://lh3.googleusercontent.com/a/ACg8ocJ-foto_1=s96-c' }),
      ),
    );
  });
});
