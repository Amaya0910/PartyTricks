// Entorno compartido de las pruebas de reglas (auditoría de seguridad).
//
// Corre contra el emulador local de Firebase con el proyecto de prueba
// "demo-party-tricks": nunca toca el proyecto real.
//
// Por defecto prueba las reglas de la raíz del repositorio. Con la variable
// REGLAS_DIR se pueden probar otras (por ejemplo, las de antes de corregir
// los hallazgos), para mostrar el antes y el después con la misma prueba.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const carpeta = process.env.REGLAS_DIR ? path.resolve(process.env.REGLAS_DIR) : raiz;

export function crearEntorno() {
  return initializeTestEnvironment({
    projectId: 'demo-party-tricks',
    firestore: {
      rules: readFileSync(path.join(carpeta, 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
    database: {
      rules: readFileSync(path.join(carpeta, 'database.rules.json'), 'utf8'),
      host: '127.0.0.1',
      port: 9000,
    },
  });
}

// Jugadores de prueba. Los uid y correos son inventados; como los de
// Firebase, los uid no llevan guion bajo (la app lo usa para unir parejas).
export const TAY = 'uidTay';
export const LEO = 'uidLeo';
export const ANA = 'uidAna';

// Id de la pareja: los dos uid en orden alfabético (como PairId en la app).
export const parDe = (a, b) => [a, b].sort().join('_');
