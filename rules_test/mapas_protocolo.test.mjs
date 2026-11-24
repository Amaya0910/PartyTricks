// Varios mapas y protocolo de versiones (database.rules.json).
//
// Varias versiones de la app comparten la misma base de datos. Estas pruebas
// comprueban que (1) las versiones viejas siguen jugando en el mapa de
// siempre, (2) un mapa nuevo solo se puede usar si está encendido en
// `config/maps` y (3) una versión que no entiende un mapa no entra a sus
// salas ni las ve en su lista pública.
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { get, ref, set, update } from 'firebase/database';
import { LEO, TAY, crearEntorno } from './entorno.mjs';

const SALA = 'sala1';

function jugador(nombre, extra = {}) {
  return { username: nombre, joinedAt: Date.now(), connected: true, ...extra };
}

function meta(extra = {}) {
  return {
    code: 'ABCDEF',
    isPublic: true,
    hostUid: TAY,
    maxPlayers: 4,
    rounds: 10,
    status: 'waiting',
    lobbyEndsAt: Date.now() + 90000,
    ...extra,
  };
}

describe('Varios mapas y protocolo de versiones', () => {
  let env;

  before(async () => {
    env = await crearEntorno();
  });

  after(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearDatabase();
  });

  /** Enciende (o apaga) un mapa en `config/maps`, como lo haría la consola. */
  const encender = (id, enabled = true) =>
    env.withSecurityRulesDisabled((ctx) =>
      set(ref(ctx.database(), `config/maps/${id}/enabled`), enabled),
    );

  /** Una sala ya creada, tal como la deja la app. */
  const sembrarSala = (metaExtra = {}, tay = {}) =>
    env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.database();
      await set(ref(db, 'roomCodes/ABCDEF'), SALA);
      await set(ref(db, `rooms/${SALA}`), {
        meta: meta(metaExtra),
        players: { [TAY]: jugador('Tay', tay) },
      });
    });

  /** Crear una sala como lo hace la app: un solo `update` con todo. */
  async function crear({ metaExtra = {}, tay = {}, lobby = null } = {}) {
    const db = env.authenticatedContext(TAY).database();
    await set(ref(db, 'roomCodes/ABCDEF'), SALA);
    return update(ref(db), {
      [`rooms/${SALA}/meta`]: meta(metaExtra),
      [`rooms/${SALA}/players/${TAY}`]: jugador('Tay', tay),
      ...(lobby ? { [`${lobby}/${SALA}`]: true } : {}),
    });
  }

  describe('las versiones viejas siguen jugando', () => {
    it('una versión vieja (sin mapId ni protocolo) crea una sala pública', async () => {
      await assertSucceeds(crear({ lobby: 'publicLobby' }));
    });

    it('una versión vieja entra a una sala del mapa de siempre', async () => {
      await sembrarSala({ mapId: 'mapa_01', requiredProtocol: 1 });
      const db = env.authenticatedContext(LEO).database();
      await assertSucceeds(set(ref(db, `rooms/${SALA}/players/${LEO}`), jugador('Leo')));
    });

    it('una sala vieja, sin ningún campo nuevo, también recibe jugadores', async () => {
      await sembrarSala();
      const db = env.authenticatedContext(LEO).database();
      await assertSucceeds(set(ref(db, `rooms/${SALA}/players/${LEO}`), jugador('Leo')));
    });

    it('la versión nueva crea una sala del mapa de siempre sin pedirle nada a Firebase', async () => {
      await assertSucceeds(
        crear({
          metaExtra: { mapId: 'mapa_01', requiredProtocol: 1 },
          tay: { protocol: 4 },
          lobby: 'publicLobby',
        }),
      );
    });
  });

  describe('un mapa nuevo solo se usa si está encendido', () => {
    const dulces = { mapId: 'mapa_dulces', requiredProtocol: 3 };

    it('apagado (sin entrada en config/maps): no se puede crear la sala', async () => {
      await assertFails(crear({ metaExtra: dulces, tay: { protocol: 4 } }));
    });

    it('con enabled en false: tampoco', async () => {
      await encender('mapa_dulces', false);
      await assertFails(crear({ metaExtra: dulces, tay: { protocol: 4 } }));
    });

    it('encendido: se crea la sala', async () => {
      await encender('mapa_dulces');
      await assertSucceeds(crear({ metaExtra: dulces, tay: { protocol: 4 } }));
    });

    it('encender un mapa no enciende los demás', async () => {
      await encender('mapa_dulces');
      await assertFails(
        crear({
          metaExtra: { mapId: 'mapa_nieve', requiredProtocol: 4 },
          tay: { protocol: 4 },
        }),
      );
    });

    it('cuando se enciende Reino Nevado, se puede crear', async () => {
      await encender('mapa_nieve');
      await assertSucceeds(
        crear({
          metaExtra: { mapId: 'mapa_nieve', requiredProtocol: 4 },
          tay: { protocol: 4 },
        }),
      );
    });

    it('un id de mapa con formato raro se rechaza aunque exista en config', async () => {
      await encender('otro_mapa');
      await assertFails(
        crear({ metaExtra: { mapId: 'Otro-Mapa!', requiredProtocol: 3 }, tay: { protocol: 4 } }),
      );
    });

    it('el mapa de una sala ya creada no se puede cambiar', async () => {
      await encender('mapa_dulces');
      await sembrarSala({ mapId: 'mapa_01', requiredProtocol: 1 });
      const db = env.authenticatedContext(TAY).database();
      await assertFails(set(ref(db, `rooms/${SALA}/meta/mapId`), 'mapa_dulces'));
    });
  });

  describe('el protocolo deja afuera a las versiones que no entienden el mapa', () => {
    const salaDeProtocolo3 = { mapId: 'mapa_dulces', requiredProtocol: 3 };

    it('una versión vieja (sin protocolo) no entra a una sala de protocolo 3', async () => {
      await sembrarSala(salaDeProtocolo3, { protocol: 4 });
      const db = env.authenticatedContext(LEO).database();
      await assertFails(set(ref(db, `rooms/${SALA}/players/${LEO}`), jugador('Leo')));
    });

    it('una versión con protocolo 2 tampoco', async () => {
      await sembrarSala(salaDeProtocolo3, { protocol: 4 });
      const db = env.authenticatedContext(LEO).database();
      await assertFails(
        set(ref(db, `rooms/${SALA}/players/${LEO}`), jugador('Leo', { protocol: 2 })),
      );
    });

    it('una versión con protocolo 3 o más sí entra', async () => {
      await sembrarSala(salaDeProtocolo3, { protocol: 4 });
      const db = env.authenticatedContext(LEO).database();
      await assertSucceeds(
        set(ref(db, `rooms/${SALA}/players/${LEO}`), jugador('Leo', { protocol: 4 })),
      );
    });

    it('no se puede decir un protocolo falso fuera de rango', async () => {
      await sembrarSala(salaDeProtocolo3, { protocol: 4 });
      const db = env.authenticatedContext(LEO).database();
      await assertFails(
        set(ref(db, `rooms/${SALA}/players/${LEO}`), jugador('Leo', { protocol: 99999 })),
      );
    });

    it('el protocolo que pide una sala no se puede bajar después de creada', async () => {
      await sembrarSala(salaDeProtocolo3, { protocol: 4 });
      const db = env.authenticatedContext(TAY).database();
      await assertFails(set(ref(db, `rooms/${SALA}/meta/requiredProtocol`), 1));
    });

    it('ni quitar el campo para que una versión vieja entre', async () => {
      await sembrarSala(salaDeProtocolo3, { protocol: 4 });
      const db = env.authenticatedContext(TAY).database();
      await assertFails(set(ref(db, `rooms/${SALA}/meta/requiredProtocol`), null));
    });
  });

  describe('listas de salas públicas', () => {
    it('publicLobby (la que lee la 1.0.0) no acepta salas de protocolo mayor', async () => {
      await encender('mapa_dulces');
      await assertFails(
        crear({
          metaExtra: { mapId: 'mapa_dulces', requiredProtocol: 3 },
          tay: { protocol: 4 },
          lobby: 'publicLobby',
        }),
      );
    });

    it('las salas de protocolo 3 se anuncian en publicLobbyByProtocol/3', async () => {
      await encender('mapa_dulces');
      await assertSucceeds(
        crear({
          metaExtra: { mapId: 'mapa_dulces', requiredProtocol: 3 },
          tay: { protocol: 4 },
          lobby: 'publicLobbyByProtocol/3',
        }),
      );
    });

    it('publicLobbyByProtocol no acepta una sala del mapa de siempre', async () => {
      await assertFails(
        crear({
          metaExtra: { mapId: 'mapa_01', requiredProtocol: 1 },
          tay: { protocol: 4 },
          lobby: 'publicLobbyByProtocol/1',
        }),
      );
    });

    it('solo el anfitrión anuncia su sala', async () => {
      await sembrarSala({ mapId: 'mapa_01', requiredProtocol: 1 });
      const db = env.authenticatedContext(LEO).database();
      await assertFails(set(ref(db, `publicLobby/${SALA}`), true));
    });
  });

  describe('config/maps', () => {
    it('los jugadores con sesión pueden leerlo', async () => {
      await encender('mapa_dulces');
      const db = env.authenticatedContext(LEO).database();
      await assertSucceeds(get(ref(db, 'config/maps')));
    });

    it('sin sesión no se lee', async () => {
      await encender('mapa_dulces');
      const db = env.unauthenticatedContext().database();
      await assertFails(get(ref(db, 'config/maps')));
    });

    it('nadie puede escribirlo desde la app, ni encender un mapa para sí', async () => {
      const db = env.authenticatedContext(TAY).database();
      await assertFails(set(ref(db, 'config/maps/mapa_dulces/enabled'), true));
      await assertFails(set(ref(db, 'config/maps'), { mapa_dulces: { enabled: true } }));
    });
  });
});
