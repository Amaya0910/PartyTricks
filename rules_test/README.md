# Pruebas de las reglas de Firebase

Pruebas automáticas de `firestore.rules` y `database.rules.json` con el
emulador local de Firebase. Salieron de la auditoría de seguridad (OWASP Mobile
Top 10): cada archivo prueba un hallazgo (`h01_…`, `h03_…`, `h04_…`, `h08_…`).

Cada archivo tiene dos tipos de prueba:

- **Ataques**: lo que un jugador malintencionado intentaría. Tienen que fallar.
- **Uso normal**: lo que la app hace de verdad. Tiene que seguir funcionando.

Corren contra el proyecto de prueba `demo-party-tricks`, que solo existe en el
emulador: **nunca tocan el proyecto real**.

## Requisitos

- Node.js 20 o más.
- Java 21 o más (sirve el que trae Android Studio: `Android Studio/jbr`).

## Cómo correrlas

```bash
cd rules_test
npm ci
npm test
```

## Antes y después

Con `REGLAS_DIR` se prueban otras reglas con las mismas pruebas, por ejemplo las
de antes de una corrección:

```bash
mkdir -p /tmp/reglas_antes
git show origin/develop:firestore.rules > /tmp/reglas_antes/firestore.rules
git show origin/develop:database.rules.json > /tmp/reglas_antes/database.rules.json
REGLAS_DIR=/tmp/reglas_antes npm test
```

Con las reglas viejas fallan las pruebas de ataque (el ataque funcionaba); con
las nuevas pasan todas.
