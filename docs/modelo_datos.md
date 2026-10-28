# Party Tricks — Modelos de datos

> Proyecto de aula · Programación Móvil
> Borrador **(propuesto)**: sale de `diseno_juego.md` y `arquitectura.md`. Los campos exactos y su ubicación en Firebase se van definiendo a medida que se construye cada área.
> Última actualización: 2026-10-27

---

## 1. Dónde vive cada dato

| Tipo de dato | Servicio | Ejemplos |
|---|---|---|
| Credenciales | Firebase Authentication | Correo y contraseña (la contraseña **no** se guarda en la base de datos del juego) |
| Datos permanentes | Cloud Firestore | Perfil, amigos, chat, catálogo de la tienda, inventario |
| Datos de la partida en vivo | Realtime Database | Salas, turnos, posiciones, presencia (desconexiones) |
| Archivos | Storage | Foto del rostro del personaje |

---

## 2. Entidades

### 2.1 Jugador (perfil)

Vive en Cloud Firestore, en `users/{uid}` (ver `decisiones.md`, D-16).

| Campo | En Firestore | Descripción |
|---|---|---|
| `uid` | id del documento | Identificador de Authentication |
| `correo` | `email` | Para iniciar sesión |
| `nombreUsuario` | `username` | Único sin distinguir mayúsculas; lo ven los demás jugadores. De 3 a 16 caracteres: letras, números y guion bajo |
| `codigoAmistad` | `friendCode` | Único; 6 caracteres sin letras que se confunden (O/0, I/1); para que otros te agreguen. Se puede cambiar desde Ajustes |
| `nombreCambiadoEn` | `usernameChangedAt` | Fecha del último cambio de nombre, en milisegundos. Solo existe si lo ha cambiado; se puede cambiar una vez cada 30 días (ver D-23) |
| `experiencia` | `experience` | XP acumulada, empieza en 0; el nivel se calcula a partir de ella |
| `monedas` | `coins` | Monedas de la cuenta, empiezan en 0 |
| `diamantes` | `diamonds` | Diamantes de la cuenta, empiezan en 0 |
| `dadosExtra` | `extraDice` | Dados extra consumibles ganados en los cofres (ver D-18); empiezan en 0. Se gastan en próximas partidas |
| `cosmeticosDesbloqueados` | _(por construir)_ | Lista de ids de cosméticos |
| `cosmeticosEquipados` | _(por construir)_ | Un cosmético por categoría |
| `fotoRostro` | _(por construir)_ | Ruta en Storage (opcional) |

#### Colecciones de Firestore de la cuenta

| Colección | Documento | Contenido | Para qué |
|---|---|---|---|
| `users` | `{uid}` | El perfil de la tabla anterior | Datos del jugador |
| `usernames` | `{nombre en minúsculas}` | `uid` y `email` | Reservar el nombre de usuario (único) y permitir iniciar sesión con él (ver D-17) |
| `friendCodes` | `{código}` | `uid` | Reservar el código de amistad (único) |

El perfil y las dos reservas se crean en la misma transacción al registrarse (o al elegir el nombre después de entrar con Google). Si el nombre o el código ya existen, la transacción falla y no se guarda nada. Cambiar el nombre o el código desde Ajustes también es una transacción: reserva el nuevo, borra el viejo y actualiza el perfil.

Las preferencias de Ajustes (notificaciones, sonido, efectos e idioma) **no** van en Firestore: se guardan en el celular con `shared_preferences` (ver D-23).

### 2.2 Cosmético

Hoy solo existe la categoría (`CosmeticCategory` en `lib/models/cosmetic_category.dart`). El cosmético como tal llega con el catálogo.

| Campo | Descripción |
|---|---|
| `id` | Identificador |
| `categoria` | Camisa, Pantalón, Zapatos, Cabello, Nariz, Ojos o Boca |
| `nombre` y `descripcion` | Texto que se muestra en la tienda |
| `precio` | En monedas o diamantes |

### 2.3 Cofre

Definido en código, en `lib/models/chest.dart` (`ChestType`). Se compran con **diamantes de la cuenta** (ver D-18). Las probabilidades salen del mockup y suman 100 %.

| Cofre | Precio (diamantes) | Cosmético aleatorio | Nada | 100 monedas | Dado extra |
|---|---|---|---|---|---|
| Básico | 50 | 25 % | 5 % | 65 % | 5 % |
| Party | 100 | 40 % | 2 % | 25 % | 33 % |
| Diamante _(nombre provisional)_ | 150 | 50 % | 0 % | 0 % | 50 % |

El mockup repite el nombre "Cofre Party" en el tercer cofre; el nombre final está por definir.

### 2.4 Amigos, chat e invitaciones

Viven en Cloud Firestore (ver `decisiones.md`, D-22). Las fechas se guardan en milisegundos, como en las salas. El **id de pareja** es el de los dos uid en orden alfabético unidos con `_` (`PairId`), así entre dos jugadores hay una sola amistad y un solo chat.

| Colección | Documento | Campos | Para qué |
|---|---|---|---|
| `publicProfiles` | `{uid}` | `username`, `friendCode`, `experience`, `photoUrl` | Lo que ven los demás (sin el correo). La app lo mantiene igual al perfil |
| `friendships` | `{id de pareja}` | `members` (los dos uid), `requestedBy`, `status` (`pending` o `accepted`), `createdAt` | Solicitud y amistad |
| `chats` | `{id de pareja}` | `members`, `lastMessage` (copia del último mensaje), `lastReadAt` (uid → fecha) | Lista de amigos: último mensaje y sin leer |
| `chats/{id}/messages` | automático | `senderId`, `text`, `sentAt`, `type` (`text` o `invite`) y, en invitaciones, `roomId` y `roomCode` | Mensajes |
| `invites` | automático | `fromUid`, `fromName`, `toUid`, `roomId`, `roomCode`, `sentAt`, `seen` | Aviso emergente de invitación |
| `blocks` | `{bloqueador}_{bloqueado}` | `blocker`, `blocked`, `createdAt` | Bloqueos |
| `reports` | automático | `reporterUid`, `reportedUid`, `reason`, `chatId`, `createdAt` | Reportes para revisar |

El nivel de la corona se calcula con `ExperienceCalculator` a partir de `experience`.

### 2.5 Sala

Vive en Realtime Database, en `rooms/{id}` (ver D-14).

| Campo | Descripción |
|---|---|
| `codigo` | Código para entrar a una sala privada |
| `creador` | Jugador que hace de "servidor" |
| `tipo` | Pública o privada |
| `maxJugadores` | Entre 2 y 6 |
| `rondas` | Entre 5 y 25 |
| `estado` | Esperando, en juego o cerrada |
| `jugadores` | Lista con su presencia (conectado o no) |

### 2.6 Partida

Vive en Realtime Database, en `rooms/{id}/game` (ver D-15).

| Campo | Descripción |
|---|---|
| `ordenTurnos` | Resultado de la tirada inicial, con el desempate por nombre |
| `rondaActual` y `turnoActual` | Dónde va la partida |
| `jugadores` | Por jugador: posición, monedas, diamantes, efecto pendiente y conteos para los premios finales |
| `casillaDiamante` | Casilla donde está el diamante |
| `fase` | Lanzando, eligiendo camino, minijuego o terminada |
| `ítems y trampas` | _(por construir, `feature/map-shop-items`)_ Casillas con trampa colocada, quién la puso y los dados extra comprados |

Conteos que se guardan para los **diamantes finales**: minijuegos ganados, casillas negativas pisadas, monedas al final y compras hechas.

### 2.7 Resultado de partida

| Campo | Descripción |
|---|---|
| `puesto` | 1º, 2º, 3º y los demás |
| `experienciaGanada` | Según la fórmula de `diseno_juego.md` (sección 11.1) |
| `monedasYDiamantes` | Lo que sobra y pasa a la cuenta |

Un jugador desconectado recibe 0 de experiencia, monedas y diamantes.

### 2.8 Estadísticas del jugador

Viven en Cloud Firestore, en `stats/{uid}` (ver `decisiones.md`, D-21), aparte del perfil para que guardar el tiempo en la app no reescriba la cuenta. El documento tiene **un mapa por grupo**; cada grupo es una clase en `lib/models/stats/`. Todo empieza en 0. Los porcentajes y promedios no se guardan: se calculan al mostrarlos.

| Grupo (mapa) | Clase | Campos |
|---|---|---|
| `matches` | `MatchStats` | `won`, `lost`, `ties`, `firstPlaces`, `secondPlaces`, `thirdPlaces`, `currentWinStreak`, `maxWinStreak`, `maxDiamonds`, `maxCoins`, `totalDiamonds`, `totalCoins`, `hosted`, `publicMatches`, `privateMatches`, `roundsPlayed`, `longestMatchSeconds` |
| `awards` | `AwardStats` | `minigames`, `worstLuck`, `richest`, `topBuyer` (veces que ganó cada diamante final) |
| `minigames` | `MinigameStats` | `won`, `lost`, `maxWonInMatch`, `bestScore` y `byType` (por id del minijuego: `played`, `won`, `bestScore`) |
| `board` | `BoardStats` | `diceRolled`, `diceTotal`, `maxRolls`, `positiveTiles`, `negativeTiles`, `specialTiles`, `mainPathsTaken`, `shortcutsTaken`, `laps`, `mapDiamonds`, `shopPurchases` |
| `shop` | `ShopStats` | `chestsOpened` (por tipo de cofre), `diamondsSpent`, `cosmeticPrizes`, `emptyPrizes`, `coinPrizes`, `dicePrizes`, `coinsFromChests` |
| `social` | `SocialStats` | `invitesSent`, `invitesAccepted`, `messagesSent`, `matchesWithFriends` y `playedWith` (por uid: `username` y `matches`) |
| `time` | `TimeStats` | `secondsInApp`, `secondsPlaying`, `secondsInMinigames`, `currentStreak`, `maxStreak`, `lastActiveDay` (`AAAA-MM-DD`, hora del celular) |

| Colección | Documento | Contenido | Para qué |
|---|---|---|---|
| `stats` | `{uid}` | Los grupos de la tabla anterior | Pantalla de Stats |
| `stats/{uid}/matches` | `{id de la sala}` | `won` y `recordedAt` | Marca de partida ya sumada, para no contarla dos veces |

**Contadores de la partida.** Para el grupo `board`, `PlayerState` (en `rooms/{id}/game`) guarda también: `diceRolled`, `diceTotal`, `maxRolls`, `positiveTiles`, `specialTiles`, `mainPathsTaken`, `shortcutsTaken`, `laps` y `mapDiamonds`. Las partidas guardadas antes los leen en 0.

---

## 3. Modelos en el código

Los modelos viven en `lib/models/`. Hoy existen:

| Archivo | Para qué |
|---|---|
| `app_section.dart` | Secciones de la barra de navegación |
| `loading_state.dart` | Estado de la pantalla de carga |
| `play_option.dart` | Opciones del menú de Jugar |
| `room.dart` | Sala de juego: configuración, jugadores y cuándo arranca o se cierra |
| `user_profile.dart` | Perfil del jugador (correo, nombre de usuario y fecha de su último cambio, código de amistad, experiencia, monedas, diamantes y dados extra) |
| `auth_user.dart` | La sesión: uid, correo, si está verificado y con qué entra (contraseña o Google) |
| `app_preferences.dart` | Preferencias de Ajustes guardadas en el celular |
| `legal_document.dart` | Textos de Acerca de, Términos y condiciones y Política de privacidad |
| `auth_form_state.dart` | Estado de los formularios de inicio de sesión y registro (cargando y mensaje de error) |
| `chest.dart` | Cofres de la tienda: precio, probabilidades, imagen y premios posibles |
| `cosmetic_category.dart` | Categorías de cosméticos del Vestuario, con su etiqueta y mensaje de "sin ítems" |
| `player_stats.dart` | Estadísticas del jugador: une los grupos de `stats/` |
| `stats/` | Un archivo por grupo de estadísticas (ver 2.8), `stats_section.dart` (tarjetas de la pantalla) y `stats_map.dart` (lectura segura de Firestore) |
| `match_summary.dart` | Lo que un jugador se lleva de una partida terminada, para sumarlo a sus estadísticas |
| `social/` | Amigos y chat: `public_profile.dart`, `friendship.dart`, `chat_message.dart`, `chat_summary.dart`, `party_invite.dart`, `report_reason.dart` y `time_map.dart` (fechas en milisegundos) |

El estado de la partida (`GameState`, `PlayerState`) y sus acciones están en `lib/services/game_engine/`, porque forman parte de las reglas del juego y no dependen de Firebase.

Los modelos de datos de este documento que faltan se agregarán a esa carpeta a medida que se construya cada área.

---

## 4. Pendientes

- [x] Estructura de las colecciones de Firestore para amigos y chat (ver 2.4).
- [ ] Estructura del catálogo de cosméticos.
- [x] Reglas de seguridad de Firestore, en `firestore.rules` (ver `decisiones.md`, D-22). Pendiente: impedir que un jugador edite por su cuenta `diamonds`, `coins` y `extraDice` (necesita Cloud Functions; ver D-18).
- [x] Forma de garantizar que el nombre de usuario y el código de amistad sean únicos (colecciones `usernames` y `friendCodes` con transacción; ver D-16).
- [x] Estructura de las salas y de la partida en Realtime Database (ver D-14 y D-15).
- [ ] Qué se guarda para permitir reconexión a una partida.
- [ ] Guardar el cosmético ganado en un cofre (hoy el premio se sortea pero no se guarda).