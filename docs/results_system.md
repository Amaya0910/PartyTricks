# Party Tricks — Resultados y XP

> Rama: `feature/results-xp`. Qué pasa cuando termina una partida: la pantalla de resultados, la XP, lo que pasa a la cuenta y qué se guarda en Firebase. Las fórmulas están en `diseno_juego.md` (secciones 10 y 11).

---

## 1. Cálculo

Se reutilizan los cálculos que ya tenía el motor. `MatchResultsBuilder` (`lib/services/game_engine/match_results.dart`) los junta en un solo `MatchResults`:

| Dato | Sale de |
|---|---|
| Diamantes finales, puestos y ganadores (empates incluidos) | `AwardCalculator` |
| XP de cada jugador | `ExperienceCalculator.xpForMatch` (puesto, jugadores y rondas) |
| Monedas y estadísticas de la partida | El `PlayerState` con que terminó cada jugador |

- El ranking va por puesto. Entre empatados va primero el de más monedas y luego por nombre.
- Los empatados comparten puesto y la misma XP (se les da la del puesto más alto).
- Del 4.º puesto en adelante no se gana XP.

El mismo `MatchResults` lo usan la pantalla, las estadísticas (`MatchSummaryBuilder`) y el registro global, así los tres siempre muestran lo mismo.

## 2. Pantalla de resultados

`lib/screens/results_screen.dart`. Reemplaza al texto provisional "¡Partida terminada! Ganó…" que había en el panel del tablero. `BoardScreen` la muestra en cuanto la partida pasa a `finished`.

| Parte | Qué muestra |
|---|---|
| Ganador | "¡Ganaste!", "¡Ganó Ana!" o "¡Empate! Ganan Ana y Beto", y las rondas jugadas |
| Lo que te llevas | Tu puesto, la XP, las monedas y los diamantes que pasan a tu cuenta |
| Clasificación | Todos los jugadores con puesto (medallas para los 3 primeros), su color, monedas, diamantes y XP. Tu fila va marcada |
| Diamantes finales | Los 4 premios y quién los ganó ("Nadie" si nadie cumplió) |
| Tu partida | Dados, casillas, atajos, vueltas, diamantes del mapa, minijuegos, compras e ítems usados |
| Volver al inicio | Vuelve a la primera pantalla de la app |

La lista se recorre hacia abajo y el botón queda fijo, así que también funciona en teléfonos pequeños.

## 3. Persistencia

Al terminar la partida, cada teléfono guarda lo suyo y el anfitrión guarda además el registro:

| Quién | Dónde | Qué | Cómo |
|---|---|---|---|
| Cada jugador | `stats/{uid}` | Estadísticas de la partida (ya existía) | Transacción de `FirebaseStatsService.recordMatch` |
| Cada jugador | `stats/{uid}/matches/{roomId}` | Marca de la partida: `won`, `place`, `experience`, `coins`, `diamonds`, `recordedAt`. Sirve de historial | La misma transacción |
| Cada jugador | `users/{uid}` | `experience`, `coins` y `diamonds` de la cuenta se suman con `FieldValue.increment` | La misma transacción |
| El anfitrión | `matchResults/{roomId}` | Registro de la partida (abajo) | Transacción de `FirebaseResultsService`: se crea una sola vez |

- **Sin doble conteo:** la XP y lo de la cuenta van en la misma transacción que la marca de la partida. Si la pantalla se reconstruye o la partida llega dos veces, la marca ya existe y no se vuelve a sumar nada. `BoardScreen` además guarda una sola vez por partida.
- **No críticos:** si falla el guardado (sin conexión), el jugador igual ve sus resultados. El error solo se anota en la consola, igual que con las estadísticas.

### 3.1 Registro global (`matchResults/{roomId}`)

Preparado para rankings globales e historial. El formato está solo en `MatchResultsDocument` (`lib/services/results/match_results_document.dart`):

```
schemaVersion: 1
roomId, hostUid, isPublic, rounds, finishedAt
winnerIds: [uid, ...]
playerIds: [uid, ...]          // para buscar "partidas de un jugador" (array-contains)
players: [                     // del primero al último
  { uid, username, place, coins, diamonds, experience, awards: ["richest", ...] }
]
```

- `MatchResultsDocument.fromMap` lo lee de vuelta (`MatchRecord`). Tolera campos faltantes y premios que no conoce, para leer registros de otras versiones.
- `schemaVersion` sube si cambia el formato.

### 3.2 Reglas de Firestore

`matchResults/{roomId}`:

- Lo lee cualquier jugador con sesión.
- Lo crea solo quien dice ser `hostUid`, que además debe estar en `playerIds`, con `roomId` igual al id del documento, `schemaVersion == 1`, máximo 6 jugadores y `players` del mismo tamaño que `playerIds`.
- No se edita ni se borra.

Se probaron 15 casos en el emulador. También se comprobó que el dueño puede sumar su XP en `users/{uid}` y que nadie más puede.

### 3.3 Compatibilidad

- No cambia nada en `rooms/{id}/game`: las partidas en curso siguen igual. Los resultados se calculan de un estado ya terminado.
- `MatchSummary.experience` vale 0 por defecto, y las marcas viejas de `stats/{uid}/matches` solo tienen `won`: siguen sirviendo para no contar dos veces.

## 4. Arquitectura

| Archivo | Qué hace |
|---|---|
| `services/game_engine/match_results.dart` | `MatchResultsBuilder`, `MatchResults`, `PlayerResult` y el nombre de cada diamante final |
| `services/stats/match_summary_builder.dart` | Usa `MatchResultsBuilder`; ahora incluye la XP |
| `services/stats/firestore_stats_document.dart` y `firebase_stats_service.dart` | Suman XP, monedas y diamantes a la cuenta dentro de la transacción de estadísticas |
| `services/results/` | `ResultsService` (interfaz), `FirebaseResultsService`, `MatchResultsDocument` y el proveedor |
| `controllers/results_controller.dart` | El anfitrión guarda el registro; no lanza errores |
| `screens/results_screen.dart` | La pantalla |
| `screens/board_screen.dart` | Muestra la pantalla al terminar y llama a los guardados. Ahora mantiene la sala escuchada (antes `isPublic` llegaba siempre `false` a las estadísticas, porque nadie la escuchaba) |

## 5. Pruebas

| Archivo | Tipo |
|---|---|
| `test/services/game_engine/match_results_test.dart` | Unitarias: orden, diamantes finales, XP por puesto, empates |
| `test/services/results/match_results_document_test.dart` | Unitarias: formato del registro, lectura de vuelta y registros incompletos |
| `test/services/stats/match_summary_builder_test.dart` | Unitarias: la XP llega a las estadísticas |
| `test/controllers/results_controller_test.dart` | Unitarias: guarda solo partidas terminadas y no lanza si falla |
| `test/services/game/results_flow_test.dart` | Integración: partida jugada con `hostApply` → resultados, estadísticas y registro coinciden |
| `test/screens/board_results_flow_test.dart` | Integración (widget): `BoardScreen` pasa a resultados, guarda una sola vez estadísticas y registro |
| `test/screens/results_screen_test.dart` | Widgets: ganador, empate, clasificación, premios, estadísticas, botón y teléfono pequeño |

## 6. Pendiente

- **Desconectados:** según el diseño, un jugador desconectado recibe 0 de XP, monedas y diamantes. Hoy todos reciben lo suyo; llega con `feature/disconnections`.
- **Ranking global:** falta la pantalla y el índice de Firestore para ordenar por `finishedAt` con `playerIds` (array-contains).
- **Confianza:** la XP y la cuenta las suma el teléfono de cada jugador, y las reglas dejan que el dueño escriba `experience`, `coins` y `diamonds` (riesgo D-18). Evitarlo del todo necesita Cloud Functions.
- **Estado de la sala:** la sala no pasa a `closed` al terminar.
