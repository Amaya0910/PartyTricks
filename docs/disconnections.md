# Party Tricks — Desconexiones

> Rama: `feature/disconnections`. Qué pasa cuando alguien pierde la conexión, cierra la app o sale de la sala, para que la partida nunca se quede trabada.

---

## 1. Resumen de los casos

| Caso | Qué pasa |
|---|---|
| Un jugador pierde la conexión | El servidor lo marca `connected: false` con la hora (`lastSeen`). Si es su turno y no vuelve en **30 s**, el anfitrión se lo salta |
| Se desconecta en la tienda (`shopping`) | Pasados los 30 s, el anfitrión lo saca de la tienda sin comprar y sigue el siguiente. La partida no se bloquea |
| Se desconecta en una bifurcación | Pasados los 30 s, sigue por el camino principal |
| Vuelve a conectarse | Se marca conectado solo. Conserva todo (posición, monedas, diamantes, mochila), porque la partida vive en la base de datos. Al jugar de nuevo deja de estar "ausente" |
| Cierra la app y la vuelve a abrir | En Inicio aparece **"Tienes una partida en curso" → Volver** |
| El anfitrión pierde la conexión | La partida sigue. Si no vuelve en **15 s**, el jugador conectado que llegó primero toma `hostUid` y su teléfono empieza a aplicar las acciones. Las que llegaron mientras tanto esperan en la fila y no se pierden |
| El anfitrión sale de la sala | Su sucesor toma `hostUid` enseguida |
| El anfitrión vuelve | Sigue jugando como uno más; el nuevo anfitrión se queda |
| Un jugador sale a mitad de partida | Se pide confirmar. Sale de la sala, sus turnos se saltan y no gana XP ni premios |
| Termina la partida desconectado | 0 de XP, monedas y diamantes para la cuenta (diseno_juego.md, sección 11). Las estadísticas sí cuentan la partida |
| El último jugador sale | Se borra la sala, su código y su lugar en la lista pública |
| Sala abandonada (nadie conectado y 2 h sin señales del anfitrión) | Cualquiera la puede borrar. Se limpian al buscar partida pública |

## 2. Tiempos (configurables)

`DisconnectionPolicy` (`lib/services/rooms/disconnection_policy.dart`), con el proveedor `disconnectionPolicyProvider`:

| Tiempo | Valor | Mínimo de las reglas |
|---|---|---|
| `hostTimeout`: espera al anfitrión antes de reemplazarlo | 15 s | 10 s. Si se pone menos, se usa 10 s |
| `turnTimeout`: espera a un jugador antes de saltar su turno | 30 s | — |
| `abandonedAfter`: sala sin nadie y sin señales | 2 h | 2 h |

Los tiempos se comparan con la **hora del servidor** (`.info/serverTimeOffset`), porque `lastSeen` la pone el servidor. Así no importa si el reloj de un celular está mal.

## 3. Cómo funciona

| Pieza | Qué hace |
|---|---|
| `PresenceService` / `FirebasePresenceService` | Escucha `.info/connected`. Al conectarse deja programado en el servidor (`onDisconnect`) `connected: false` + `lastSeen`, y luego se marca `connected: true`. Si se cae la red, el servidor hace el cambio solo |
| `RoomGuard` (`lib/controllers/room_guard.dart`) | Corre en cada teléfono mientras está en la espera o en la partida (cada 2 s): presencia, sucesión del anfitrión con `claimHost`, latido `lastActiveAt` (el anfitrión, una vez por minuto) y salto de turnos (el anfitrión) |
| `RoomService.claimHost` | Transacción sobre `meta/hostUid`: solo cambia si el anfitrión sigue siendo el que se fue. Si dos lo intentan a la vez, gana uno |
| `SkipTurn` (motor) | Acción que solo manda el anfitrión. Juega lo mínimo por el ausente: pierde la tirada, toma el camino principal o sale de la tienda. Lo marca `away` y suma `missedTurns` |
| `BoardScreen` | Empieza o deja de aplicar las acciones (`runHost`) según quién sea el anfitrión en ese momento. Guarda `activeGames/{uid}` y pregunta antes de salir |
| `LobbyScreen` | También usa `RoomGuard`: si el creador se va de la sala de espera, el sucesor sigue con la cuenta regresiva y arranca o cierra la sala |
| `ActiveGameBanner` | En Inicio ofrece volver a la partida en curso. Si la sala ya no existe o ya no estás en ella, se olvida sola |
| `RoomService.leave` | Saca al jugador; si era el último, borra la sala |
| `RoomService.cleanAbandoned` | Quita de `publicLobby` las salas que no existen y borra las abandonadas. Se llama antes de buscar partida pública |

## 4. Persistencia

| Dónde | Campo | Para qué |
|---|---|---|
| `rooms/{id}/players/{uid}` | `connected`, `lastSeen` | Presencia (`lastSeen` es nuevo) |
| `rooms/{id}/meta` | `hostUid` | Puede cambiar a otro jugador de la sala |
| `rooms/{id}/meta` | `lastActiveAt` | Latido del anfitrión (nuevo) |
| `rooms/{id}/game/players/{uid}` | `away`, `missedTurns` | Ausente y turnos saltados (nuevos) |
| `rooms/{id}/actions` | `{type: 'skip', playerId}` | Saltar turno (nuevo) |
| `activeGames/{uid}` | id de la sala | Volver a la partida tras cerrar la app (nuevo) |
| `stats/{uid}/matches/{roomId}` | `disconnected` | Si terminó desconectado (nuevo) |

**Compatibilidad:** todos los campos nuevos son opcionales. Las salas y partidas guardadas antes se leen igual: sin `lastSeen`, un jugador desconectado cuenta como ido hace rato; sin `lastActiveAt`, se cuenta desde el fin de la espera; sin `away`, es `false`.

## 5. Reglas de Realtime Database

| Regla | Qué permite y qué no |
|---|---|
| `meta` (cambio de anfitrión) | Un jugador de la sala puede ponerse **a sí mismo** como `hostUid` solo si el anfitrión salió o lleva `connected: false` con `lastSeen` de hace más de 10 s. Al hacerlo no puede cambiar `status`, `lobbyEndsAt` ni `lastActiveAt` |
| `meta` (traspaso) | El anfitrión puede pasar el lugar, pero solo a un jugador de la sala |
| `meta/lastActiveAt` | Solo el anfitrión, y nunca en el futuro |
| `players/{uid}/lastSeen` | Solo el propio jugador, nunca en el futuro. Al entrar alguien a la sala no puede cambiar el de los demás. Un jugador que salió no puede volver a crearse con la presencia |
| `actions` tipo `skip` | Solo el anfitrión |
| `rooms/{id}` (borrar) | Cualquiera con sesión, si la sala no tiene jugadores o lleva 2 h abandonada |
| `roomCodes` y `publicLobby` (borrar) | El anfitrión o cualquiera, si la sala ya no existe después de la escritura |
| `activeGames/{uid}` | Solo su dueño lee y escribe |

Se probaron **33 casos** en el emulador, y se repitieron los 15 de las tiendas del mapa para comprobar que siguen igual.

## 6. Pruebas

| Archivo | Tipo |
|---|---|
| `test/services/rooms/disconnection_policy_test.dart` | Unitarias: sucesor, esperas, mínimos de las reglas, saltar turno, salas abandonadas, `lastSeen` y `lastActiveAt` en el modelo |
| `test/services/game_engine/skip_turn_test.dart` | Unitarias: `SkipTurn` en cada fase, volver, resultados de ausentes, codec |
| `test/controllers/room_guard_test.dart` | Unitarias: presencia, sucesión, latido, salto con reintento, errores |
| `test/services/game/disconnection_flow_test.dart` | Integración: el anfitrión y una jugadora en la tienda se caen; otro toma el anfitrión, la partida sigue, ella vuelve con su estado y la partida termina |
| `test/screens/board_disconnection_test.dart` | Integración (widgets): `BoardScreen` empieza y deja de ser anfitrión, salir a mitad de partida, aviso de Inicio |

## 7. Pendiente y riesgos

- **Anfitrión de confianza:** el anfitrión decide cuándo saltar un turno. Uno con la app modificada podría saltar turnos de jugadores conectados. Las reglas solo verifican que sea el anfitrión. Evitarlo del todo necesita Cloud Functions, como el resto del cálculo (D-15).
- **Salas privadas abandonadas:** solo se limpian solas las públicas (al buscar partida) y las que quedan vacías. Una privada que todos dejan sin salir queda hasta que alguien la abra desde "partida en curso". Una limpieza total necesita una Cloud Function programada.
- **Minijuego:** si el anfitrión se cae durante el minijuego provisional, el nuevo anfitrión ve el botón "Simular minijuego". Con minijuegos reales habrá que revisar quién cierra el minijuego.
- **Celular sin señal mucho rato:** al volver la conexión se marca conectado, pero si se saltaron sus turnos solo deja de estar ausente cuando vuelve a jugar.
- Falta subir las reglas (`firebase deploy --only database`) y probar con varios celulares, cortando el wifi.
