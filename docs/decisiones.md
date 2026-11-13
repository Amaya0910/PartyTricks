# Party Tricks — Decisiones técnicas

> Proyecto de aula · Programación Móvil
> Cada decisión dice **qué** se decidió, **por qué** y **qué alternativas** había. Se agregan al final, con la fecha.

---

## Cómo agregar una decisión

```markdown
## D-00. Título corto

- **Fecha:** AAAA-MM-DD
- **Estado:** Propuesta / Aceptada / Reemplazada
- **Decisión:** qué se eligió.
- **Motivo:** por qué.
- **Alternativas:** qué otras opciones se vieron.
```

---

## D-01. Flutter para la app

- **Estado:** Aceptada
- **Decisión:** una sola base de código en Flutter para el móvil.
- **Motivo:** es la tecnología del curso y permite probar en emulador y en celular.

## D-02. Firebase como backend

- **Estado:** Aceptada
- **Decisión:** Authentication, Cloud Firestore, Realtime Database y Storage.
- **Motivo:** evita montar un servidor propio y da datos en tiempo real, que el juego necesita.
- **Reparto:** Firestore para datos permanentes y Realtime Database para la partida en vivo y la detección de desconexiones.
- **Pendiente:** confirmar el reparto exacto durante `chore/firebase-setup`.

## D-03. Riverpod como gestor de estado

- **Estado:** Aceptada
- **Decisión:** `flutter_riverpod`.
- **Motivo:** maneja bien los flujos en tiempo real de Firebase, facilita entregar servicios por interfaz y hace más fácil probar la app.
- **Alternativas:** Provider (más simple) y Bloc (más estructura y más código).

## D-04. El celular del creador de la sala hace de "servidor"

- **Estado:** Aceptada para el proyecto de aula
- **Decisión:** el creador valida las acciones y calcula los resultados (dado, movimiento, monedas, efectos); luego se guardan en Firebase.
- **Motivo:** no requiere código en servidor.
- **Riesgo:** un jugador con la app modificada podría hacer trampa. Si el juego se publicara, el cálculo pasaría a Cloud Functions.
- **Respaldo:** toda la partida se guarda en Firebase, así que otro jugador puede tomar el rol si el creador se desconecta.

## D-05. Capas y separación de responsabilidades

- **Estado:** Aceptada
- **Decisión:** `Pantallas → Controladores (Riverpod) → Servicios → Firebase`, con las carpetas `controllers`, `models`, `screens`, `services` y `widgets`.
- **Motivo:** las pantallas no hablan con Firebase directamente y las reglas del juego se pueden probar sin la interfaz.

## D-06. Una sola fuente de colores

- **Estado:** Aceptada
- **Decisión:** todos los colores se definen en `lib/theme/app_colors.dart`. Ningún widget usa `Color(0x...)` ni `Colors.algo`. Los colores de la barra de navegación se aplican desde el tema (`app_theme.dart`).
- **Motivo:** cambiar un color del mockup se hace en un solo lugar y la app queda consistente.
- **Regla práctica:** si hace falta un color nuevo, se agrega a `AppColors` y se avisa al equipo, porque es un archivo compartido.

## D-07. Navegación con barra inferior que conserva el estado

- **Estado:** Aceptada
- **Decisión:** `MainShellScreen` usa `IndexedStack`, así cada sección conserva su estado al cambiar de pestaña.
- **Detalle:** el `switch` de secciones es exhaustivo; si se agrega una sección, Dart avisa dónde falta.

## D-08. Íconos de la barra de navegación

- **Estado:** Aceptada
- **Decisión:** se mantienen los íconos de Material (`Icons.*`) en lugar de exportar los de Figma.
- **Motivo:** decisión del equipo de diseño; el estilo del botón activo ya cumple con lo esperado.

## D-09. Flujo de trabajo en Git

- **Estado:** Aceptada
- **Decisión:** ramas `main` y `develop`, una rama por tarea (`feature/...`, `fix/...`), una rama permanente para la documentación (ver D-20), commits con prefijo y Pull Request revisado por la otra persona.
- **Detalle completo:** ver `roles_y_ramas.md`.

## D-10. Foto del rostro opcional y chat moderable

- **Estado:** Aceptada
- **Decisión:** la foto de rostro es opcional (se puede armar el personaje con cosméticos) y el chat debe permitir reportar y bloquear.
- **Motivo:** el público es de 10 a 27 años, así que hay jugadores menores y se guardan fotos de rostros.
- **Pendiente:** definir la moderación del chat y la privacidad de las fotos.
- **Actualización (2026-11-06):** la foto de la cara ya existe y sigue siendo opcional; cómo se guarda y quién la ve está en D-32.

## D-11. Flutter Casual Games Toolkit como referencia; Flame solo si un minijuego lo necesita

- **Estado:** Propuesta (por confirmar con Brayan)
- **Origen:** recomendación del profesor de usar Flutter para juegos y el kit de herramientas de Flutter (Flutter Casual Games Toolkit).
- **Decisión:**
  - El tablero, los dados, los turnos, las tiendas y los resultados se hacen con Flutter normal y Riverpod, sin motor de juego.
  - Las plantillas del toolkit (`basic`, `card` y `endless_runner`) y sus ejemplos (como `multiplayer`) se usan como **referencia**, no se adoptan completas.
  - **Flame** (motor de juegos para Flutter) se usa únicamente en los minijuegos de tiempo real que lo necesiten. Se decide **por minijuego**.
- **Motivo:** el toolkit considera que los juegos por turnos encajan bien en Flutter solo y reserva Flame para los de tiempo real. El tablero de Party Tricks es por turnos; los minijuegos son la única parte que podría ser de tiempo real.
- **Alternativas:** usar Flame para todo el juego (más complejidad sin beneficio para un tablero por turnos) o no usar el toolkit.
- **Pendientes:**
  - Revisar qué gestor de estado usan las plantillas, porque puede ser distinto de Riverpod.
  - Hacer una prueba corta de Flame con el minijuego más sencillo antes de decidir.
  - Cuando se defina la lista de minijuegos, anotar cuáles usan Flame.

## D-12. Configuración del proyecto de Firebase

- **Fecha:** 2026-10-17
- **Estado:** Aceptada
- **Decisión:** proyecto `party-tricks` (plan Spark, gratis) con apps Android e iOS registradas con el identificador `com.partytricks.app`. Se activaron Authentication (correo y contraseña), Cloud Firestore (ubicación `nam5`) y Realtime Database (`us-central1`), ambas en modo de prueba. La configuración la genera `flutterfire configure` en `lib/firebase_options.dart`, y `main.dart` inicia Firebase antes de abrir la app.
- **Motivo:** el identificador `com.example` no se acepta en tiendas y cambiarlo después obliga a registrar las apps otra vez. Correo y contraseña es lo que pide el diseño del juego.
- **Pendientes:**
  - Escribir las reglas de seguridad antes de que venza el modo de prueba (30 días desde el 2026-10-17, es decir, hacia el **2026-11-16**).
  - Storage pide el plan Blaze (de pago); se decide cuando llegue `feature/player-profile` con la foto del rostro.
  - Para entrar a la consola de Firebase, pedir acceso a Brayan.

## D-13. Motor del juego y valores provisionales

- **Fecha:** 2026-10-17
- **Estado:** Propuesta (por confirmar con Isabella)
- **Decisión:** las reglas de la partida están en `lib/services/game_engine/` en Dart puro, sin Firebase. `GameEngine.apply(estado, acción)` devuelve un estado nuevo; el teléfono anfitrión lo usa y sube el resultado. El azar pasa por `RandomSource` para poder probarlo.
- **Valores provisionales** (se cambian en un solo lugar):
  - Tablero de 42 casillas: camino principal 0-29, bifurcaciones en 5, 15 y 24, tiendas en 12 y 22. Las posiciones se ajustan cuando esté el dibujo.
  - Casilla positiva +3 monedas, negativa −3 y efectos especiales de monedas ±5.
  - Cada jugador empieza con 10 monedas y el ganador del minijuego recibe 10.
  - El diamante del mapa se gana al pasar por su casilla y reaparece en otra al azar (nunca en la salida ni en las tiendas).
  - En una bifurcación el jugador se detiene y elige el camino.
  - Si nadie tiene nada en una categoría de diamante final (por ejemplo, nadie compró), nadie lo recibe.
- **Pendientes:** las compras y los dados extra se conectan en `feature/map-shop-items`, y las desconexiones en `feature/disconnections`.

## D-14. Salas en Realtime Database

- **Fecha:** 2026-10-17
- **Estado:** Propuesta (por confirmar con Isabella)
- **Decisión:** las salas viven en Realtime Database: `rooms/{id}/meta` (código, pública o privada, creador, jugadores máximos, rondas, estado y fin de la espera), `rooms/{id}/players/{uid}`, `roomCodes/{código}` para buscar por código y `publicLobby/{id}` para las salas públicas que esperan jugadores. El código tiene 6 caracteres sin letras que se confunden (O/0, I/1). El teléfono del creador decide cuándo arranca o se cierra la sala, y una transacción evita que dos jugadores entren al último puesto a la vez.
- **Actualizado (D-22):** las salas ya usan el uid y el nombre de usuario real de la cuenta (`room_providers.dart`). Solo si no hay sesión se entra como usuario anónimo con el nombre "Jugador XXXX". Al arrancar la partida todos pasan al tablero.
- **Pendientes:** ~~reglas de seguridad de Realtime Database~~ (hechas en `database.rules.json`, D-24), borrar salas viejas y qué pasa si el creador se sale (va en `feature/disconnections`).

## D-15. Partida en vivo y pantalla del tablero

- **Fecha:** 2026-10-18
- **Estado:** Propuesta (por confirmar con Isabella)
- **Decisión:** el estado de la partida se guarda en `rooms/{id}/game` y solo lo escribe el teléfono del creador (anfitrión). Los jugadores mandan sus acciones a `rooms/{id}/actions`; el anfitrión las aplica con el motor en orden y borra cada una en la misma escritura. Las acciones fuera de turno se ignoran.
- **Provisional:** el tablero se dibuja en una cuadrícula de 9×8 (camino principal por el borde, caminos alternos por dentro) hasta tener el dibujo de Isabella. Como aún no hay minijuegos, el creador tiene un botón "Simular minijuego" que sortea al ganador. La pantalla de resultados llega en `feature/results-xp`.
- **Pendientes:** salir a mitad de partida y cambio de anfitrión (`feature/disconnections`).

## D-16. Cuentas y perfiles de jugador

- **Fecha:** 2026-10-20
- **Estado:** Aceptada
- **Decisión:** Firebase Authentication guarda el correo y la contraseña. El perfil vive en Cloud Firestore, en `users/{uid}`, con correo, nombre de usuario, código de amistad, experiencia, monedas y diamantes (los tres últimos empiezan en 0). Para que el nombre de usuario y el código de amistad sean únicos se usan dos colecciones de reserva, `usernames/{nombre en minúsculas}` y `friendCodes/{código}`, que se crean en la **misma transacción** que el perfil. Si el nombre ya existe, el registro se rechaza; si el código se repite, se genera otro (hasta 5 intentos). Si algo falla después de crear la cuenta en Authentication, esa cuenta se elimina para que no quede una cuenta sin perfil.
- **Reglas de los datos:**
  - Nombre de usuario: de 3 a 16 caracteres (letras, números y guion bajo), único sin distinguir mayúsculas.
  - Contraseña al registrarse: mínimo 8 caracteres, con una mayúscula, una minúscula, un número y un símbolo. Al iniciar sesión solo se pide que no esté vacía, para que las cuentas anteriores puedan entrar.
  - Código de amistad: 6 caracteres sin letras ni números que se confunden (O/0, I/1), igual que los códigos de sala.
- **En el código:** `lib/services/auth/` (interfaz `AuthService` y su versión con Firebase), `AuthController` con Riverpod y `lib/models/user_profile.dart`. El perfil se sigue en vivo con `userProfileProvider`, y `AppGate` decide qué pantalla mostrar: carga, acceso (sin sesión) o la app (con sesión).
- **Motivo:** una transacción evita que dos jugadores se queden con el mismo nombre o código a la vez, sin necesitar un servidor. Entregar el servicio por interfaz permite probar el controlador con uno falso.
- **Alternativas:** consultar el nombre solo en el perfil (no garantiza la unicidad si dos personas se registran a la vez) o usar Cloud Functions (requiere el plan Blaze).
- **Pendientes:**
  - Botón de cerrar sesión, cambiar contraseña y recuperarla.
  - ~~Cambiar `room_providers.dart` para que las salas usen el nombre de usuario real~~ (hecho en D-22).
  - Reglas de seguridad de Firestore.

## D-17. Inicio de sesión con correo o nombre de usuario

- **Fecha:** 2026-10-20
- **Estado:** Aceptada para el proyecto de aula
- **Decisión:** en el inicio de sesión se acepta el correo o el nombre de usuario (sin distinguir mayúsculas). Firebase Authentication solo entra con correo, así que al registrarse se guarda el correo dentro de `usernames/{nombre}`. Al iniciar con un nombre, se lee ese documento para obtener el correo y luego se autentica. Las cuentas creadas antes de esta decisión completan ese dato la primera vez que inician sesión con su correo.
- **Motivo:** es lo que pide el mockup de la pantalla de acceso.
- **Riesgo:** la búsqueda ocurre antes de tener sesión, así que `usernames` debe poder leerse sin iniciar sesión. Si las reglas permitieran listar la colección, cualquiera vería los correos de todos los jugadores, y hay jugadores menores (ver D-10).
- **Alternativas:** iniciar solo con correo (más simple y sin exponer correos) o Cloud Functions que conviertan el nombre en correo sin mostrarlo (requiere el plan Blaze).
- **Hecho (D-22):** en `firestore.rules`, `usernames` solo se lee por nombre exacto (`get`), nunca se lista (`list`), y solo su dueño lo escribe.

## D-18. Tienda de cofres con diamantes

- **Fecha:** 2026-10-26
- **Estado:** Propuesta (por confirmar con Brayan)
- **Decisión:** los cofres (Básico 50, Party 100 y Diamante 150) se compran con los **diamantes de la cuenta**. Los premios son: cosmético aleatorio, nada, 100 monedas o dado extra. Las probabilidades salen del mockup y viven en `lib/models/chest.dart`. El sorteo está en `ChestRoller`, que usa `RandomSource` para poder probarlo. `FirebaseShopService` cobra y entrega el premio en **una sola transacción** de Firestore sobre `users/{uid}`. El dado extra se guarda en el campo `extraDice` del perfil.
- **En el código:** `lib/models/chest.dart`, `lib/services/shop/` (interfaz `ShopService`, versión con Firebase, `ChestRoller` y proveedores), `ShopController`, y los widgets `chest_dialog.dart` y `chest_visuals.dart`. Las imágenes están en `assets/images/cofres/`.
- **Motivo:** una transacción evita cobrar sin dar premio o gastar dos veces el mismo diamante. Entregar el servicio por interfaz permite probar sin Firebase.
- **Provisional:**
  - El tercer cofre se llama "Cofre Diamante" porque el mockup lo repite como "Cofre Party".
  - El premio "cosmético" todavía no se guarda: falta el catálogo (hay un `TODO` en `firebase_shop_service.dart`).
  - La tienda aún no tiene ítems (cosméticos a la venta).
- **Riesgo:** el cobro lo calcula el celular del jugador. Las reglas de Firestore deben impedir que un jugador edite por su cuenta `diamonds`, `coins` y `extraDice`; si no, puede hacer trampa.
- **Pendientes:** catálogo de cosméticos e ítems de la tienda. Las reglas de Firestore ya están (`firestore.rules`, D-22), pero dejan que el dueño escriba `diamonds`, `coins` y `extraDice`: evitarlo del todo necesita Cloud Functions.

## D-19. Vestuario con datos provisionales

- **Fecha:** 2026-10-26
- **Estado:** Propuesta
- **Decisión:** `WardrobeController` guarda la categoría activa (`CosmeticCategory`: camisa, pantalón, zapatos, cabello, nariz, ojos y boca). Los cosméticos que se muestran son un mapa fijo en `wardrobe_screen.dart` (solo "Camisa 1"). Si la categoría no tiene ítems, se muestra su mensaje de "Aún no tienes...".
- **Motivo:** permite construir y revisar la interfaz del mockup antes de que exista el catálogo de cosméticos.
- **Pendientes:** reemplazar el mapa por los cosméticos desbloqueados del perfil, poder equiparlos, armar el personaje y conectar el botón "Foto" (hoy muestra "La cámara llega pronto").
- **Actualización (2026-11-06):** la piel, los ojos y la boca ya son reales (D-29, D-30 y D-31); el mapa fijo con "Camisa 1" queda solo para las categorías sin arte (camisa, pantalón, zapatos, cabello y nariz).

## D-20. Una rama permanente para la documentación

- **Fecha:** 2026-10-26
- **Estado:** Aceptada
- **Decisión:** toda la documentación se actualiza en una sola rama, `docs/documentacion-completa`, que no se borra. Antes de editar se trae `develop` a esa rama, y los cambios se unen a `develop` con Pull Request. Las demás ramas ya unidas se borran.
- **Motivo:** mantener la menor cantidad de ramas posible y tener un lugar fijo para actualizar los documentos.
- **Alternativas:** crear una rama `docs/<tema>` nueva en cada actualización (más ramas que limpiar).
- **Detalle:** comandos en `roles_y_ramas.md`, sección 3.

## D-21. Estadísticas del jugador

- **Fecha:** 2026-10-27
- **Estado:** Propuesta (por confirmar con Brayan)
- **Decisión:** las estadísticas viven en Cloud Firestore, en `stats/{uid}`, aparte del perfil, con un mapa por grupo (partidas, premios finales, minijuegos, tablero, tienda, social y tiempo). Cada jugador guarda las suyas:
  - **Partida:** al terminar, `BoardScreen` arma un `MatchSummary` (con `MatchSummaryBuilder` y `AwardCalculator`) y `StatsCalculator` lo suma. La suma y una marca en `stats/{uid}/matches/{id de la sala}` van en **una sola transacción**, así una partida nunca se cuenta dos veces. Como hay un minijuego por ronda, los minijuegos jugados son las rondas.
  - **Tablero:** el motor cuenta en `PlayerState` los dados, el número máximo, el tipo de casilla, el camino elegido, las vueltas y los diamantes del mapa. Son solo contadores: no cambian las reglas.
  - **Cofres:** `FirebaseShopService` suma el cofre, el gasto y el premio en la **misma transacción de la compra**, con `FieldValue.increment`.
  - **Tiempo jugando y en minijuegos:** lo mide `MatchTimeTracker` con los cambios de fase.
  - **Tiempo en la app:** `AppUsageTracker` envuelve a `MainShellScreen` y cuenta mientras la app está en primer plano. Se guarda con `FieldValue.increment` cada minuto y al pasar a segundo plano.
  - **Racha:** `StreakCalculator` cuenta los días seguidos en que se abre la app, con la fecha del celular.
  - **Social:** `StatsController.recordSocial` queda listo para invitaciones y mensajes (`feature/friends-chat`).
- **En el código:** `lib/models/player_stats.dart`, `lib/models/stats/`, `lib/models/match_summary.dart`, `lib/services/stats/` (interfaz `StatsService`, versión con Firebase, `FirestoreStatsDocument`, calculadoras, formato y proveedores), `StatsController`, `StatsPresenter`, `StatsScreen` y los widgets `stats_card.dart` y `app_usage_tracker.dart`. En el motor: `game_state.dart`, `game_engine.dart` y `game_codec.dart`.
- **Motivo:** un grupo por clase evita una clase gigante y deja cada parte con una sola responsabilidad. `FirestoreStatsDocument` es el único lugar que conoce la ruta y los incrementos, así la tienda y el servicio no se separan. Las calculadoras y el presentador no dependen de Firebase ni del reloj real, así que se prueban solos.
- **Provisional:**
  - El mejor puntaje y los minijuegos por tipo quedan vacíos hasta que existan minijuegos (hoy se simula al ganador).
  - Las compras en tiendas del mapa quedan en 0 hasta `feature/map-shop-items`.
  - Invitaciones, mensajes y partidas con amigos quedan en 0 hasta `feature/friends-chat`.
- **Riesgo:** como el resto de la partida (ver D-04), las estadísticas las escribe el celular del jugador. Para el proyecto de aula es aceptable.
- **Pendientes:**
  - ~~Reglas de Firestore para `stats/{uid}`~~ (hechas en `firestore.rules`, D-22).
  - Cuando llegue `feature/results-xp`, la pantalla de resultados puede reutilizar `MatchSummaryBuilder`.

## D-22. Amigos, chat e invitaciones

- **Fecha:** 2026-10-27
- **Estado:** Propuesta (por confirmar con Brayan)
- **Decisión:**
  - **Perfil público:** lo que ven los demás vive en `publicProfiles/{uid}` (nombre, código, experiencia y foto), **sin el correo**, porque hay jugadores menores (D-10). `PublicProfilePublisher` lo mantiene igual al perfil cada vez que este cambia, y solo escribe si algo cambió.
  - **Amistad por solicitud:** se envía con el código de amistad (`friendCodes/{código}` → uid). Entre dos jugadores hay un solo documento, `friendships/{id de pareja}`, con estado `pending` o `accepted`; se crea en una transacción. Si los dos se envían solicitud, queda aceptada. Rechazar, cancelar y eliminar borran el documento.
  - **Chat:** `chats/{id de pareja}` guarda el último mensaje y hasta cuándo leyó cada uno (para el punto de "sin leer"); los mensajes van en `chats/{id}/messages`. El mensaje y el resumen se escriben juntos en un `WriteBatch`. Máximo 200 caracteres. Solo se puede escribir a amigos.
  - **Invitaciones:** desde **Tu party**, con **Invitar a amigos**. Cada invitación se guarda en `invites` (para el aviso emergente) y como mensaje del chat de tipo `invite`, en la misma escritura. El botón del mensaje cambia según el estado de la sala en Realtime Database. El aviso solo sale en el menú principal y si la party aún espera jugadores.
  - **Bloquear y reportar:** bloquear crea `blocks/{bloqueador}_{bloqueado}` y borra la amistad en la misma escritura. Quien está bloqueado no puede escribir, enviar solicitudes ni invitar; no se le dice que lo bloquearon. Reportar guarda el caso en `reports` para que lo revise un adulto o el docente.
  - **Estadísticas:** se suman los mensajes enviados, las invitaciones enviadas y aceptadas, y las partidas con al menos un amigo (D-21).
  - **Nombre en la sala:** `roomIdentityProvider` usa el uid y el nombre de usuario real de la cuenta, para que los amigos se reconozcan en la sala.
- **En el código:** `lib/models/social/`, `lib/services/social/` (una interfaz y su versión con Firebase por tema: `ProfileDirectory`, `FriendsService`, `ChatService`, `InviteService` y `ModerationService`; `FirestoreSocialPaths` es el único lugar que conoce las rutas; lógica pura en `PairId`, `ChatRules`, `FriendsSections`, `ChatFormat` e `InviteStatus`), los controladores `FriendsController`, `ChatController`, `InviteController`, `ModerationController` y `PublicProfileController`, las pantallas `friends_screen.dart` y `chat_view.dart`, y los widgets de amigos, chat y diálogos.
- **Motivo:** un servicio por tema deja cada clase con una sola responsabilidad y permite probar los controladores con servicios falsos. Las reglas del negocio (solo a amigos, bloqueos, límites) viven en los controladores y en `ChatRules`, no en la interfaz.
- **Alternativas:** guardar los amigos dentro de cada perfil (cada jugador tendría que escribir en el perfil del otro) o usar notificaciones push para las invitaciones (necesitan Cloud Functions y el plan Blaze).
- **Riesgo:** las reglas de Firestore son las que de verdad impiden que alguien lea chats ajenos o escriba sin ser amigo. Sin ellas, cualquiera con la app modificada podría hacerlo.
- **Reglas de Firestore:** están en `firestore.rules`, en la raíz del proyecto, y se publican desde la consola de Firebase (Firestore Database → Reglas). Cubren todas las colecciones de Firestore, no solo las de amigos:
  - `users` y `stats`: solo su dueño.
  - `usernames` y `friendCodes`: solo por nombre o código exacto, nunca la lista.
  - `publicProfiles`: lo leen todos los jugadores con sesión; lo escribe su dueño.
  - `friendships`: solo los dos jugadores de la pareja; aceptar solo cambia el estado.
  - `chats` y sus mensajes: solo la pareja; los mensajes solo entre amigos, a nombre propio, de máximo 200 caracteres y si el otro no te bloqueó.
  - `invites`: solo a amigos que no te bloquearon; el invitado solo puede marcarlas como vistas.
  - `blocks`: los crea y los borra quien bloquea.
  - `reports`: se pueden crear, pero nadie los lee desde la app.
- **Pendientes:**
  - ~~Lista de bloqueados para desbloquear~~: hecha en Ajustes → Más opciones → Jugadores bloqueados (D-23).
  - Foto de perfil en el perfil público (llega con la foto del rostro).
  - Ver si un amigo está conectado.

## D-23. Ajustes, verificación del correo e inicio con Google

- **Fecha:** 2026-10-27
- **Estado:** Propuesta (por confirmar con Brayan)
- **Decisión:**
  - **Ajustes** se abre al tocar la foto de perfil en Inicio o en Stats. Tiene cuatro bloques, como en el mockup: el código de amistad, la cuenta, las preferencias y "Más opciones".
  - **Código de amistad:** se puede copiar y recargar. Recargar reserva un código nuevo en `friendCodes` y libera el viejo en la misma transacción. Los amigos actuales se conservan; el código viejo deja de servir para agregarte.
  - **Nombre de usuario:** se puede cambiar **una vez cada 30 días** (`AccountRules.usernameCooldown`). La fecha del último cambio se guarda en `users/{uid}.usernameChangedAt`. El nombre nuevo se reserva en `usernames` y el viejo se borra en la misma transacción; el perfil público se actualiza solo (D-22).
  - **Correo y contraseña:** los dos piden la contraseña actual, porque Firebase lo exige. El correo nuevo se cambia con `verifyBeforeUpdateEmail`: el cambio se aplica cuando el jugador abre el enlace, y al iniciar sesión otra vez la app copia el correo nuevo al perfil y a `usernames`. Las cuentas que solo usan Google no tienen estas dos opciones.
  - **Verificación del correo:** al registrarse se envía el enlace. **Se puede jugar sin verificar**: Inicio y Ajustes muestran un aviso con **Reenviar** y **Ya lo verifiqué** hasta que el correo esté verificado. Las cuentas que ya existían también lo ven. Las cuentas de Google no lo ven, porque Google ya verifica el correo.
  - **Inicio con Google** (`google_sign_in` 7): botón "Continuar con Google" en la tarjeta de inicio de sesión. Si el correo ya tenía cuenta con contraseña, Firebase une las dos formas de entrar en la misma cuenta (mismo uid). Quien entra con Google por primera vez elige su nombre de usuario en una pantalla aparte (`ChooseUsernameScreen`), que crea el perfil, el nombre y el código como en el registro.
  - **Preferencias** (notificaciones, sonido, efectos de sonido): se guardan en el celular con `shared_preferences`, no en Firestore. Por ahora no hay sonidos ni notificaciones; los interruptores quedan listos para cuando existan. El idioma es solo español.
  - **Más opciones:** Acerca de, Términos y condiciones, Política de privacidad (textos en `LegalDocument`, con contacto del equipo de Party Tricks: Isabella Amaya y Brayan Vasquez), Jugadores bloqueados (con **Desbloquear**) y Cerrar sesión.
- **En el código:** `lib/screens/settings_screen.dart`, `change_password_screen.dart`, `legal_screen.dart`, `blocked_players_screen.dart` y `choose_username_screen.dart`; los controladores `AccountController` y `PreferencesController`; los servicios `AccountService` (y `FirebaseAccountService`), `PreferencesService` (y `SharedPreferencesService`) y `GoogleIdTokenSource`; las reglas puras en `AccountRules`; los mensajes de error de Firebase en `FirebaseErrorMessages`; los modelos `AuthUser`, `AppPreferences` y `LegalDocument`; los widgets `settings_section.dart`, `code_digits.dart`, `text_fields_dialog.dart`, `verify_email_banner.dart` y `google_sign_in_button.dart`.
- **Motivo:** los cambios de la cuenta van en `AccountService`, separado de `AuthService` (registro e inicio), para que cada clase tenga una sola responsabilidad. Google se pide a través de `GoogleIdTokenSource` para poder probar el servicio sin el paquete. Las preferencias en el celular evitan escrituras a Firestore por cosas que solo importan en ese dispositivo.
- **Alternativas:** obligar a verificar el correo antes de jugar (más seguro, pero frena a quien quiere probar el juego), guardar las preferencias en Firestore (sirve entre celulares, pero hoy no hace falta) o dejar cambiar el nombre sin límite (permite confundir a los demás jugadores).
- **Configuración necesaria:**
  - Activar el proveedor **Google** en Firebase Authentication.
  - Agregar las huellas **SHA-1** y **SHA-256** de cada computador que compile la app (Configuración del proyecto → Android) y volver a descargar `google-services.json`.
  - En iOS: `GoogleService-Info.plist`, `GIDClientID` y el esquema de URL `REVERSED_CLIENT_ID` en `Info.plist`.
- **Riesgo:** el límite de 30 días para cambiar el nombre lo revisa la app, no las reglas de Firestore; alguien con la app modificada podría saltárselo.
- **Pendientes:**
  - Activar los sonidos y las notificaciones cuando existan.
  - Más idiomas.

## D-24. Reglas de seguridad de Realtime Database

- **Fecha:** 2026-10-28
- **Estado:** Propuesta (por confirmar con Isabella)
- **Decisión:** las reglas están en `database.rules.json` y `firebase.json` ahora apunta a las dos reglas (`database` y `firestore`), para subirlas con `firebase deploy --only database,firestore`. Todo está cerrado salvo lo que la app usa:
  - **Leer:** cualquier usuario con sesión (también el anónimo) lee `roomCodes`, `publicLobby` y `rooms/{id}`. Hace falta porque las invitaciones del chat leen salas en las que el jugador todavía no está. Sin sesión no se lee nada.
  - **`roomCodes/{código}`:** se crea solo si está libre; lo borra solo el creador de la sala a la que apunta. El código debe tener 6 caracteres del alfabeto de `RoomCodeGenerator`.
  - **`publicLobby/{id}`:** lo escribe solo el creador y solo si la sala es pública; el valor es `true`.
  - **`rooms/{id}/meta`:** se crea solo si el código ya está reservado para esa sala y el creador es quien escribe. Después solo el creador la cambia, y no puede cambiar el código, el creador, si es pública, el cupo ni las rondas. Se revisan los tipos y rangos (2-6 jugadores, 5-25 rondas, estados `waiting`/`playing`/`closed`).
  - **`rooms/{id}/players/{uid}`:** cada jugador escribe y borra solo lo suyo, y solo entra mientras la sala espera. Para la transacción de `_join` se permite escribir la lista completa solo a quien todavía no está y queda dentro; no puede cambiar los datos de los demás ni agregar a otros.
  - **`rooms/{id}/game`:** solo lo escribe el creador (anfitrión).
  - **`rooms/{id}/actions/{id}`:** solo las mandan los jugadores de la sala mientras se juega. `roll` y `branch` deben llevar el uid propio en `playerId`; `minigame` solo la manda el anfitrión. Solo el anfitrión las borra.
  - `reactions`, `results` y cualquier otra ruta quedan cerradas hasta que existan.
- **Motivo:** el modo de prueba deja que cualquiera borre todo, se haga anfitrión o cambie la partida, y además vence alrededor del 2026-11-16. Las reglas siguen las rutas que ya usa el código (D-14 y D-15) sin cambiar nada en Dart.
- **Alternativas:** abrir la lectura solo a los jugadores de la sala (rompe las invitaciones) o pasar la entrada a la sala a Cloud Functions (más seguro, pero necesita el plan Blaze).
- **Riesgos que quedan:** las reglas de Realtime Database no pueden contar hijos, así que el cupo de la sala lo controla la transacción de la app, y alguien con una app modificada podría, al entrar, sacar a otros de la sala de espera o pasarse del cupo. El anfitrión sigue siendo de confianza: si su teléfono hace trampa, las reglas no lo detectan. Las salas viejas no se borran.
- **Pendientes:** en `feature/disconnections` hay que dejar que otro jugador tome `meta/hostUid` (hoy las reglas lo bloquean) y abrir `players/{uid}/connected` para `onDisconnect` (ya lo permite, porque es del propio jugador).
- **Cómo se probaron:** con el emulador de Realtime Database y 25 casos (los flujos de la app y los ataques de arriba), todos como se esperaba.

## D-25. Mapa dibujado armado en Tiled

- **Fecha:** 2026-10-28
- **Estado:** Aceptada (Brayan está de acuerdo)
- **Decisión:**
  - El tablero se muestra como un **mapa dibujado** en vista ¾, con piezas reutilizables (ver `docs/arte_imagenes.md`). El mundo mide 2880 × 4320 px.
  - El mapa se arma en **Tiled** (gratis) y la app lee **directamente** el archivo que guarda, `assets/maps/mapa_01/mapa.tmj`, sin script de conversión. Se esperan conjuntos de patrones **incrustados** de tipo colección de imágenes, una capa de objetos `casillas` con la propiedad entera `casilla` en cada plataforma, y otras capas de objetos para tiendas, puentes y decoraciones.
  - El archivo de Tiled **solo dice dónde va cada cosa**. Los tipos de casilla y cómo se conectan están en `buildDefaultBoard()` (`board_layout.dart`), que pasó al primer mapa: camino principal de la 0 a la 31, desvío A (1 → 32…36 → 8) y desvío B (13 → 37…41 → 23), tiendas en 17 y 36, 4 especiales y 14 negativas fijas. Si al mapa le falta alguna casilla, la app muestra el tablero de cuadritos.
  - Las pruebas del motor usan su propio tablero (`test/services/game_engine/test_board.dart`, el de antes), para que cambiar el mapa no las rompa.
  - El código pone solo las marcas de casilla, el caminito de piedra (la textura repetida entre cada casilla y las siguientes, que se bifurca solo), el diamante, las flechas de las bifurcaciones y el personaje.
  - Se ven **todos los jugadores**; la cámara sigue al tuyo. Cada uno camina saltando de casilla en casilla por el camino más corto entre su posición anterior y la nueva. Si varios comparten casilla, se ponen uno al lado del otro.
  - En las bifurcaciones se elige tocando una de **dos flechas** que apuntan a cada camino. Reemplazan los botones Seguir y Atajo (que se quedan solo en el tablero de respaldo).
  - Se hace con widgets de Flutter (`InteractiveViewer` + `Stack`), no con Flame (D-11). La parte fija va en un `RepaintBoundary` para que mover la cámara sea liviano.
- **En el código:** `lib/models/map/board_map.dart`, `lib/services/map/` (`TiledMapParser`, `BoardWalk`, `MapAssets` y `map_providers.dart`) y `lib/widgets/map/` (`BoardMapView`, `MapScenery` y `MapPathsPainter`). `board_screen.dart` cambia la vista y el panel.
- **Motivo:** leer el archivo de Tiled tal cual permite cambiar el mapa sin tocar código, y separar las pruebas del motor del mapa real permite cambiar el mapa sin romperlas.
- **Alternativas:** escribir las coordenadas a mano en un JSON propio (más errores) o usar Flame (otra dependencia sin beneficio para un tablero por turnos).
- **Pendientes:**
  - Monedas animadas en las casillas positivas (crecen, suben y desaparecen solo para ti).
  - Minimapa.
  - Hojas de animación del personaje en lugar del círculo con la foto.
  - Más mapas: el anfitrión sortearía uno y lo guardaría en la partida (toca el estado de Brayan).

## D-26. Minijuegos: Para el Tiempo, Reacción y Globo Bomba

- **Fecha:** 2026-10-29
- **Estado:** Propuesta (por confirmar con Isabella)
- **Decisión:**
  - Tres minijuegos con **una sola arquitectura** (`lib/services/game_engine/minigames.dart`): `MinigameType` (id que se guarda), `MinigameRules` (tiempos y rangos en un solo lugar), `MinigameState` (el minijuego en curso), `MinigameResult` (cómo terminó) y `MinigameJudge` (las reglas, sin guardar nada). El motor sortea el minijuego al terminar la ronda y paga con la misma función que antes (`_finishMinigame`): monedas y `minigamesWon`.
  - El minijuego en curso vive **dentro de la partida** (`rooms/{id}/game/minigame`) y el último resultado en `rooms/{id}/game/lastMinigame`. Por eso sobrevive a **reconexiones** y a un **cambio de anfitrión** sin pasos extra.
  - **Cada teléfono mide su propio tiempo** desde que muestra el minijuego (explicación de 3 s incluida) y manda su puntaje con la acción `minigameMove` (`playerId`, `round`, `score`). Así no importa si los relojes de los teléfonos no coinciden ni cuánto tarda la red: lo que cuenta es el tiempo en la pantalla de cada uno. El anfitrión solo junta los puntajes y decide.
  - Los números al azar (objetivo, espera, capacidad del globo y el dado del desempate) los sortea **el anfitrión** con el `RandomSource` del motor, igual que los dados del tablero.
  - Para que nadie trabe la ronda, el anfitrión corre un **árbitro** (`MinigameReferee`, dentro de `RoomGuard`): cuenta desde que ve cada paso del minijuego y, pasado el límite (`MinigameRules.timeLimit`: el tiempo del minijuego más 5 s de margen), manda `minigameTimeout` (`round`, `step`). En Para el Tiempo y Reacción cierra con lo que haya; en el Globo Bomba infla 1 por quien no jugó. `step` sube con cada jugada, así un cierre viejo se ignora. Si cambia el anfitrión, el nuevo empieza a contar desde que lo ve: a lo mucho se espera un poco más.
  - Las jugadas repetidas, de otra ronda, de quien no juega o fuera de rango lanzan `StateError` y el anfitrión las ignora (`hostApply`), como el resto de acciones.
  - Se **quita** el botón provisional "Simular minijuego". `FinishMinigame` se queda: lo usan el motor por dentro y las pruebas de antes. Un `GameEngine` sin minijuegos configurados (`minigames: []`, el valor por defecto) sigue esperando `FinishMinigame`; la app usa los tres (`gameEngineProvider`).
  - Partidas guardadas en fase de minijuego **sin** minijuego armado (de antes de este bloque): el árbitro manda `minigameTimeout` a los 5 s y la ronda se cierra sin ganador.
- **En el código:** `lib/services/game_engine/minigames.dart` (nuevo), `game_state.dart`, `game_action.dart` (`MinigameMove`, `MinigameTimeout`), `game_engine.dart`, `game_codec.dart`; `lib/services/game/minigame_referee.dart` (nuevo) y `lib/controllers/room_guard.dart`; pantallas en `lib/widgets/minigames/` (`MinigameView`, `StopwatchGame`, `ReactionGame`, `BalloonGame` y `MinigameResultOverlay`) y `board_screen.dart`, que muestra el minijuego en lugar del mapa.
- **Reglas (`database.rules.json`):** se permiten las acciones `minigameMove` (solo con el uid propio en `playerId`, `round` de 1 a 25 y `score` de -1 a 25000) y `minigameTimeout` (solo el anfitrión, `step` desde 0). Las demás reglas no cambian.
- **Motivo:** guardar todo en la partida reutiliza lo que ya funciona para reconexiones y anfitriones (D-24, bloque 5), y medir en cada teléfono evita sincronizar relojes, que en Realtime Database sin servidor propio no es exacto.
- **Alternativas:** marcar el inicio con la hora del servidor (`ServerValue.timestamp`) y comparar tiempos de llegada (depende de la red de cada uno) o Cloud Functions como árbitro (necesita el plan Blaze).
- **Riesgos que quedan:**
  - El puntaje lo manda cada teléfono: una app modificada podría mandar un tiempo falso. Las reglas solo revisan el rango.
  - Los números secretos (espera de Reacción, capacidad del globo) están en la partida, que todos los jugadores pueden leer. La pantalla no los muestra, pero una app modificada sí podría.
  - Quien vuelve a abrir la app en pleno Para el Tiempo o Reacción empieza a contar de nuevo.
  - Las estadísticas por tipo de minijuego (`MinigameStats.byType`) todavía no se llenan: la partida guarda solo el último resultado.
- **Cómo se probaron:** 61 pruebas nuevas (reglas de cada minijuego, desempate con el dado, cierre por tiempo, árbitro, cambio de anfitrión, reconexión, guardado en la base de datos y pantallas). Las reglas de Realtime Database no se probaron con el emulador en este bloque (en esta computadora falta Java 21).

## D-27. Cuenta de administración y pruebas

- **Fecha:** 2026-11-05
- **Estado:** Propuesta
- **Decisión:**
  - Una cuenta es **administradora** si existe el documento `admins/{uid}` en Firestore. Se crea **a mano** desde la consola de Firebase (puede estar vacío); las reglas no dejan crearlo, cambiarlo ni listarlo desde la app. Cada cuenta solo puede leer el suyo.
  - En Ajustes aparece la tarjeta **Administración** solo para esas cuentas. El panel vuelve a revisar el permiso al abrirse.
  - El panel tiene cuatro partes:
    - **Galería de pantallas:** práctica de minijuegos en el teléfono contra dos rivales de mentira (las mismas reglas de `MinigameJudge` y las mismas pantallas, sin Firebase), tarjetas de resultado de cada minijuego, tirada del dado, pantalla final con una partida de ejemplo, tonos de piel del personaje y algunos diálogos. Nada se guarda.
    - **Estadísticas de la app:** cuentas, XP, monedas y diamantes guardados (`users`), partidas terminadas y públicas (`matchResults`), minijuegos ganados, tiempo en la app y diamantes gastados (`stats`), y las últimas 5 partidas. Se calculan con consultas de conteo y suma de Firestore, sin descargar los documentos.
    - **Economía:** sumar monedas, diamantes y dados extra a la cuenta propia, o dejarlos en 0, para probar la tienda y los cofres.
    - **Desarrollo:** uid (se puede copiar), correo, XP, tamaño de pantalla, tamaño de letra, modo de compilación, ver los bordes de los widgets (solo en depuración) y reiniciar las preferencias.
- **En el código:** `lib/services/admin/` (`AdminService`, `FirebaseAdminService`, `admin_providers.dart`), `lib/models/admin/app_overview.dart`, `lib/controllers/admin_controller.dart`, `lib/screens/admin/` y la tarjeta en `settings_screen.dart`.
- **Reglas (`firestore.rules`):** nueva función `isAdmin()`; `admins/{uid}` solo se lee por su dueño; `users` y `stats` se pueden **leer** (no escribir) si eres administrador. Hay que publicarlas con `firebase deploy --only firestore:rules`.
- **Motivo:** probar las pantallas desde el teléfono sin armar una partida con varias personas, y ver cómo se usa la app, sin pagar el plan Blaze.
- **Alternativas:** *custom claims* de Firebase Auth (necesitan el Admin SDK o Cloud Functions para asignarlas) o una lista de uids en el código (solo esconde el panel; no protege los datos).
- **Riesgos que quedan:**
  - Las herramientas de economía solo funcionan para administradores: desde D-28 las reglas no dejan que un jugador cambie su cartera a mano.
  - Las sumas de toda la app leen todas las cuentas: con muchos jugadores habría que guardar contadores aparte.

## D-28. Los jugadores no escriben su propia cartera

- **Fecha:** 2026-11-05
- **Estado:** Propuesta
- **Decisión:**
  - La **cartera** del perfil (`coins`, `diamonds`, `extraDice` y `experience` en `users/{uid}`) ya no se puede escribir libremente. Al crear la cuenta tiene que estar en 0, y cualquier otro cambio del perfil (nombre, correo, tono de piel...) no puede tocarla.
  - Solo hay tres formas de cambiarla, y las reglas revisan cada una:
    - **Comprar un cofre** (`isChestPurchase`): se restan exactamente 50, 100 o 150 diamantes, sin quedar en negativo, y como mucho se suman 100 monedas **o** 1 dado extra. La XP no cambia.
    - **Cobrar una partida** (`isMatchReward`): en la misma transacción se crea la marca `stats/{uid}/matches/{id}` (que no existía) y el perfil anota el id en `lastRewardMatch`. Lo que se suma tiene que ser **exactamente** lo de ese jugador en `matchResults/{id}`. La marca ya no se puede cambiar ni borrar, así que cada partida se cobra una sola vez.
    - **Administración** (D-27): el administrador puede cambiar su propia cartera.
  - `matchResults` ahora tiene **topes** por jugador: monedas de 0 a 10 000, diamantes de 0 a 100 y XP de 0 a 300 (lo máximo que da `ExperienceCalculator` es 280).
  - Como el anfitrión guarda `matchResults` al mismo tiempo que cada jugador cobra, `FirebaseStatsService.recordMatch` vuelve a intentar hasta 4 veces (a los 2, 4, 8 y 16 s) si las reglas lo rechazan.
- **En el código:** `firestore.rules`, `FirestoreStatsDocument.matchRewards` (agrega `lastRewardMatch`), `FirebaseStatsService.recordMatch` (reintentos) y un aviso en `lib/models/chest.dart`: los precios y el premio de monedas también están en las reglas.
- **Motivo:** antes cualquier jugador con una app modificada podía ponerse las monedas y diamantes que quisiera. Sin servidor propio, lo más que se puede hacer es que cada cambio tenga que coincidir con algo registrado.
- **Alternativas:** Cloud Functions que entreguen los premios y cobren los cofres (lo más seguro, pero necesita el plan Blaze) o mover la cartera a otra colección sin escritura desde la app (igual necesitaría un servidor).
- **Riesgos que quedan:**
  - El sorteo del cofre sigue en el teléfono: una app modificada podría elegir siempre el premio que quiera, pero pagando el precio del cofre.
  - Quien es anfitrión podría guardar un `matchResults` inventado (con un id nuevo) y cobrarlo, dentro de los topes. Las reglas de Firestore no pueden leer la partida de Realtime Database para comprobarlo.
  - Un jugador desconectado (que no gana nada) podría cobrar lo que dice el registro.
  - La XP de `publicProfiles` la sigue escribiendo cada jugador.
  - Las reglas **no se probaron con el emulador** (en esta computadora faltan Firebase CLI y Java 21). Antes de publicarlas conviene probar: comprar cada cofre, terminar una partida (anfitrión y no anfitrión), cambiar el nombre y el tono, y que el panel de administración pueda sumar.

## D-29. Ojos a la venta en la Tienda

- **Fecha:** 2026-11-05
- **Estado:** Propuesta
- **Decisión:**
  - Los ojos 2, 5 y 7 vienen **gratis** con la cuenta (los que ya se veían en el Vestuario). Los otros 8 se compran con **monedas** en la Tienda, debajo de los cofres, con el diseño del mockup: el dibujo en un cuadro punteado y, al lado, nombre, descripción y precio.
  - Precios provisionales: 30 (Ojos Pequeñitos), 45 (Burbuja, Somnolientos, Felices), 60 (Aburridos, Curiosos, Despistados) y 75 (Pícaros). Quedan cerca de las camisas del mockup (45) y se juntan con una o dos partidas o con un cofre de monedas.
  - Al tocar un ojo se abre una ventana con tu personaje (con tu tono de piel y tu color de ojos) probándoselos, cuántas monedas tienes y el botón Comprar. Si no alcanzan, dice cuántas faltan. Lo comprado sale de la Tienda y aparece en el Vestuario.
  - El perfil guarda los ojos comprados en `ownedEyes` (lista de números; los gratis no se guardan). La compra cobra y agrega el ojo en una sola transacción.
- **Reglas (`firestore.rules`):** `ownedEyes` es parte de la cartera (D-28): empieza vacía y solo cambia con `isEyesPurchase`, que exige agregar **un** ojo que se vende y restar **exactamente** su precio (`eyesPrice`), sin tocar nada más. Los ojos puestos (`eyes`) tienen que ser gratis o comprados. Los precios están repetidos en `lib/models/eye_style.dart` y en las reglas: si cambian, hay que cambiarlos en los dos.
- **En el código:** `EyeStyle` (nombre, descripción y precio), `UserProfile.ownedEyes`, `ownedEyesProvider` y `eyesForSaleProvider` (`eyes_controller.dart`), `ShopService.buyEyes`, `ShopController.buyEyes`, `ShopScreen`, `ShopItemRow` y `EyesPurchaseDialog`.
- **Pendientes:**
  - El premio "Cosmético aleatorio" de los cofres todavía no da nada: podría regalar un ojo que no tengas (habría que permitirlo en `isChestPurchase`).
  - Las demás categorías (camisas, pantalones...) pueden usar la misma fila y la misma idea cuando tengan arte.
  - Las reglas no se probaron con el emulador.

## D-30. Bocas con color y filtro en la Tienda

- **Fecha:** 2026-11-06
- **Estado:** Propuesta
- **Decisión:**
  - Las bocas 1 y 3 vienen **gratis** con la cuenta (la inicial es la 1). Las otras 8 se compran con **monedas** en la Tienda, igual que los ojos (D-29): 30 (2 y 4), 45 (5 y 6), 60 (7 y 8) y 75 (9 y 10).
  - La boca tiene color, con los mismos 20 colores de los ojos, pero la posición 0 es **sin color**: la parte blanca de la boca toma el **tono de piel** del personaje (en la línea de colores se muestra con el tono de piel). Con otro color, lo blanco toma ese color y lo negro sigue negro (`BlendMode.modulate`).
  - Solo se tiñe la capa que tiene el blanco: la línea en la boca 8; las de un solo PNG se tiñen enteras. Las bocas 1, 9 y 10 no se tiñen nunca (la 1 se queda con sus dientes blancos; la 9 y la 10 tienen colores propios). En la boca 2 el color es el del labial.
  - La Tienda ahora mezcla ojos y bocas, así que se agregó un **filtro** de chips (Todos / Ojos / Bocas) sobre la lista. La ventana de compra es una sola (`CosmeticPurchaseDialog`) para cualquier cosmético.
  - El perfil guarda `mouth` (número), `mouthColor` (posición) y `ownedMouths` (las compradas; las gratis no se guardan).
- **Reglas (`firestore.rules`):** `ownedMouths` es parte de la cartera (D-28) y solo cambia con `isMouthPurchase` (una boca que se vende y su precio exacto, `mouthPrice`). La boca puesta tiene que ser gratis o comprada. Los precios están repetidos en `lib/models/mouth_style.dart` y en las reglas: si cambian, hay que cambiarlos en los dos. **Hay que publicar las reglas nuevas** o las compras de bocas se rechazan.
- **En el código:** `MouthStyle`, `MouthColor`, `UserProfile.mouth/mouthColor/ownedMouths`, `mouth_controller.dart`, `MouthLayer`, `MouthPicker`, `ShopService.buyMouth`, `ShopController.buyMouth` y `ShopScreen` (filtro).
- **Pendientes:**
  - Los nombres y descripciones de las bocas son provisionales.
  - El premio "Cosmético aleatorio" de los cofres sigue sin dar nada.
  - Las reglas no se probaron con el emulador.

## D-31. Rareza, cosméticos en los cofres y foto de perfil con la cabeza

- **Fecha:** 2026-11-06
- **Estado:** Propuesta
- **Decisión:**
  - Cada ojo y cada boca tiene una **rareza** (`Rarity`: común, poco común, raro, épico, legendario; índice 1 a 5). La Tienda la muestra junto al precio y se puede **ordenar** (recomendado, precio y rareza) además de filtrar por categoría.
  - Los **cofres ya regalan cosméticos**: cuando sale "Cosmético aleatorio", se sortea entre los de la Tienda que el jugador todavía no tiene, con un peso por rareza (50, 28, 14, 6 y 2). Si ya los tiene todos, el premio se cambia por 100 monedas. El cosmético se guarda en `ownedEyes` u `ownedMouths` en la misma transacción que cobra el cofre.
  - Los ojos Pícaros suben a 100 monedas (legendarios). La boca Gatuna pasó a llamarse Boca Titubeante.
  - Al abrir un cofre sale una **ventana de premio** (`ChestRewardDialog`) con los colores del cofre: el cosmético con su rareza, las monedas, el dado extra o el cofre vacío. El cuadro del premio es un widget aparte para cambiarlo por una animación de sorteo más adelante.
  - La **foto de perfil** es la cabeza del personaje (piel, ojos y boca) sobre un color de fondo que se elige en Ajustes > Preferencias (16 colores, campo `avatarColor`). Como la ven los demás, el perfil público (`publicProfiles`) ahora también guarda `skinTone`, `eyes`, `eyeColor`, `mouth`, `mouthColor` y `avatarColor`. Si el jugador puso su foto, la cabeza la lleva (D-32).
  - El Vestuario ya no muestra el nombre bajo cada cosmético.
- **Reglas (`firestore.rules`):** `isChestPurchase` acepta, además de los premios de antes, que se agregue **un** ojo o **una** boca de los que se venden y que no cambie nada más. Precio de los ojos 11: 100.
- **Riesgos que quedan:** el sorteo del cosmético se hace en el teléfono (igual que el del premio): una app modificada podría escoger el que quiera, pero pagando el cofre y solo entre los que se venden. Las fotos de perfil de los jugadores en el Lobby y el tablero siguen siendo las provisionales (`PartyCharacter`).
- **Pendientes:** animación para el sorteo del cosmético; las reglas no se probaron con el emulador; los jugadores que no han abierto la app desde este cambio se ven con la cabeza inicial hasta que su perfil público se actualice.

## D-32. Foto de la cara en el personaje

- **Fecha:** 2026-11-06
- **Estado:** Propuesta
- **Decisión:**
  - El jugador puede ponerle su cara al personaje. Es **opcional**: se puede apagar para volver a los ojos y la boca, o quitar.
  - La foto **cubre toda la cabeza**, en lugar de los ojos y la boca. Se recorta con la forma real de la cabeza, sacada de `relleno_cabeza.png`, y el contorno negro se dibuja encima.
  - Tiene **pantalla propia** (`FacePhotoScreen`), que se abre con el botón **Foto** del Vestuario, con tres partes:
    - **Cámara en vivo** con la silueta de la cabeza y líneas para los ojos y la boca; lo que queda fuera se oscurece. También se puede elegir una foto de la galería.
    - **Editor:** mover, acercar, girar y voltear, con los dedos o con controles. Al lado, el personaje muestra el recorte real. Lo que se ve es lo que se guarda: la pantalla y el recorte usan las mismas medidas (`FaceCrop`).
    - **Resumen:** el personaje en la escena del juego, con Otra foto, Ajustar, el interruptor y Quitar mi foto.
  - La foto se guarda en **Firestore**, no en Storage: un JPEG de 256 × 256 en base64 en `users/{uid}.facePhoto`, con `useFacePhoto` para el interruptor. Storage suele pedir el plan de pago, y una imagen de ese tamaño cabe en el documento.
  - La ven **todos los jugadores**: si está activa, se copia a `publicProfiles/{uid}.facePhoto`. Se ve en Inicio, el Vestuario, la foto de perfil, los amigos, el chat y las invitaciones. Al apagarla o quitarla, deja de publicarse.
- **Alternativas:**
  - `image_picker` también para la cámara: no deja dibujar la silueta encima, por eso se usa el paquete `camera` y `image_picker` queda solo para la galería.
  - Un círculo sobre la cara, con la foto a 128 × 128: se veía pegado encima y borroso.
- **Reglas (`firestore.rules`):** `facePhotoOk` limita el texto a 60 000 caracteres en `users` y en `publicProfiles`. El mismo tope está en `FacePhoto.maxLength`: si cambia, hay que cambiarlo en los dos sitios. **Hay que publicar las reglas.**
- **En el código:** `FacePhoto`, `FaceCrop` y `FaceSourceImage` (`face_photo.dart`), `FaceImageProcessor` (`face_image_service.dart`), `FaceCamera`, `FacePhotoController`, `HeadShape`, `FacePhotoLayer`, `FaceCameraView`, `FacePhotoEditor`, `FacePhotoSheet` y `FacePhotoScreen`.
- **Riesgos que quedan:**
  - No hay moderación de imágenes y cualquier jugador con sesión puede leer las fotos de `publicProfiles`. Hay jugadores menores: hay que definirlo antes de publicar la app (ver D-10).
  - El editor de una foto ya guardada parte de los 256 × 256 guardados, no del original: sirve para retoques pequeños.
  - El contorno de la cabeza está escrito en `head_shape.dart`: si cambia `relleno_cabeza.png`, hay que trazarlo otra vez.
- **Pendientes:**
  - Probar la cámara real: permiso, encuadre y si la foto frontal sale como espejo (el botón **Voltear** lo corrige a mano).
  - Decidir si se quita de Android el permiso `RECORD_AUDIO`, que declara el paquete `camera` aunque la app no graba audio.
  - El lobby y el tablero siguen con el personaje provisional, sin foto.
  - Las reglas no se probaron con el emulador.

## D-33. Camisas, accesorios y caminata de lado

- **Fecha:** 2026-11-07
- **Estado:** Propuesta
- **Decisión:**
  - **Camisas** (`ShirtStyle`, 19) y **accesorios** (`AccessoryStyle`, 2) se compran en la Tienda con monedas y salen en los cofres, igual que los ojos y las bocas (D-29 a D-31). Cada uno tiene su pestaña en el Vestuario (**Camisa** y **Accesorios**, esta nueva) y su filtro en la Tienda.
  - **Camisa de inicio:** la camisa 1, **azul** (id 1, gratis). La camisa 1 es blanca y se tiñe: tiene **8 colores más** en la Tienda (ids 101 a 108, 30 monedas cada uno). Las demás camisas traen su color y no se tiñen. La camisa 2 se queda como está, sin mangas.
  - **Precios y rarezas** (los puse yo; se pueden cambiar): camisa 1 de colores, 30 (común); camisa 2, 45 (poco común); camisas 3 y 4 (fútbol), 60 (rara); camisa 5 (payaso), 75 (épica); camisas 6 y 7, 45; 8 y 9, 60; 10 y 11, 75; 12, 100 (legendaria). Accesorios: orejas de ogro, 75 (épico); gorguera de bufón, 100 (legendario). Ninguno es gratis salvo la camisa azul.
  - **Se guardan** en el perfil: `shirt` (id; si falta, la 1), `ownedShirts`, `accessory` (id; **0 = ninguno**) y `ownedAccessories`. El perfil público también guarda `shirt` y `accessory` (el accesorio se ve en la foto de perfil).
  - **Dibujo.** De frente, la camisa va con el cuerpo y cada manga con su brazo (gira con él, debajo de la mano). Los accesorios van con la cabeza. De lado, la camisa va con el torso y la manga (una sola para los dos brazos) con cada brazo. `camisa_5` se ve distinta yendo a la derecha o a la izquierda, así que de lado trae un dibujo para cada una; las demás se voltean junto con el cuerpo. Las carpetas nuevas están declaradas en `pubspec.yaml` (una prueba lo revisa: si falta una, el personaje se dibuja sin la camisa, en silencio).
  - **Caminata de lado** (`WalkingCharacter`): dos piernas y dos brazos que se mueven en sentidos contrarios. Los personajes del mapa caminan así de casilla en casilla y quietos se ven de frente. Las animaciones están en `CharacterClip`; **Administración → Galería → Animaciones** las muestra todas, con el personaje del administrador tal como lo tiene puesto.
  - Para tratar los cuatro cosméticos igual en la Tienda y los cofres existe `ShopCosmetic` (lo implementan `EyeStyle`, `MouthStyle`, `ShirtStyle` y `AccessoryStyle`). `ChestPrize` y `CosmeticPicker` ahora también reparten camisas y accesorios; las probabilidades de los cofres cambian porque hay más cosméticos que sortear.
- **Reglas (`firestore.rules`):** `shirtPrice`, `accessoryPrice`, `isShirtPurchase`, `isAccessoryPurchase`, `addsOneShirt` y `addsOneAccessory`; el cofre puede dar uno de los cuatro, y la camisa y el accesorio puestos tienen que ser el de inicio o comprados. Los precios están también en `shirt_style.dart` y `accessory_style.dart`: **una prueba compara las dos listas**. **Hay que publicar las reglas.**
- **Pendientes:**
  - **Colecciones** (por ejemplo, camisas 3 y 4 de fútbol; camisas 6 a 12, primer drop de Shift's): todavía no existen. Los nombres de las camisas del drop ya dicen "Shift's".
  - Un cofre especial solo de cosméticos.
  - Los demás jugadores se dibujan en el mapa con el aspecto de inicio: la partida todavía no trae el aspecto de cada uno (el del perfil público ya está disponible).
  - `camisa_5_derecha` se usa cuando el personaje mira a la derecha: si está al revés, se intercambian en `ShirtStyle.bodyAsset`.
  - Pantalón, zapatos, cabello y nariz siguen sin arte.
  - Las reglas no se probaron con el emulador.

## D-34. Margen de 200 px arriba del lienzo del personaje

- **Fecha:** 2026-11-08
- **Estado:** Propuesta
- **Decisión:** el lienzo del personaje pasa de 512 × 768 a **512 × 968**: se agregaron 200 px transparentes **arriba** de todas las capas (157 PNG de `personaje/`), para tener espacio para el cabello y los sombreros. El dibujo no cambió, solo bajó 200 px.
- **En el código:** `kCharacterTopMargin` y `kCharacterCanvas` (`character_layer.dart`). Todo lo medido en píxeles del lienzo (pivotes de `BodyPart`, articulaciones de `WalkingCharacter`, recortes de los selectores y de `HeadAvatar`, `HeadShape.zone`, línea de los pies del mapa) suma ese margen. En el mapa el cuerpo mide lo mismo que antes.
- **Reposo de lado** (`CharacterClip.idleSide`, `SideIdle`): solo se ve en el Vestuario, con un botón para ver el personaje de lado. En las partidas, al dejar de caminar, el personaje se pone de frente con el reposo normal.
- **Para el arte nuevo:** exportar a 512 × 968. En Krita: Imagen → Cambiar tamaño del lienzo, alto 968 y desplazamiento Y = 200 (el dibujo existente baja).

## D-35. Cabellos

- **Fecha:** 2026-11-08
- **Estado:** Propuesta
- **Decisión:**
  - Hay **10 cabellos** (`HairStyle`). Se compran en la Tienda con monedas y salen en los cofres, igual que las camisas y los accesorios (D-33). Ninguno es gratis. Tienen pestaña propia en el Vestuario (**Cabello**) y filtro en la Tienda (**Cabellos**).
  - **Sin cabello:** el primer espacio de la pestaña es "Ninguno", con una **X roja**. Es el estado de inicio: el campo `hair` vale 0.
  - **Color:** los cabellos blancos (2, 6, 7 y 9) toman el color que elija el jugador (`HairColor`, los mismos 20 colores de los ojos; el primero es blanco = el dibujo original). **Todos los colores están desbloqueados**: no se compran. Los otros seis (1, 3, 4, 5, 8 y 10) traen su color y no se tiñen. Si más adelante se venden colores, habrá que guardar cuáles tiene cada jugador.
  - **Precios y rarezas** (los puse yo; se pueden cambiar): 1, 5 y 9, 45 (poco común); 2, 3, 6 y 10, 60 (raro); 4, 7 y 8, 75 (épico).
  - **Se guardan** en el perfil: `hair` (id; 0 = ninguno), `ownedHairs` y `hairColor` (posición del color). El perfil público también guarda `hair` y `hairColor`: el cabello se ve en la foto de perfil.
  - **Dibujo.** `cabello_<id>.png` va **encima de la cara** (ojos y boca) y **debajo de los accesorios**, de frente y de lado. Los cabellos 1, 3 y 6 traen además `cabello_<id>_atras.png` (solo de frente), que va **detrás de la cabeza**.
  - **Reglas (`firestore.rules`):** `hairPrice`, `isHairPurchase`, `addsOneHair`, `onlyHairsChange` y `ownedHairs` en la cartera; el cabello puesto tiene que ser 0 o comprado; el cofre puede dar uno. Una prueba compara los precios de las reglas con los del código. **Hay que publicar las reglas.**
- **Además:** el icono de la pestaña **Accesorios** del Vestuario (`Icons.auto_awesome`; antes no tenía ninguno).
- **Pendientes:**
  - La foto de perfil recorta alrededor de la cabeza (`HeadAvatar._crop`): los cabellos muy altos (el 7) se ven cortados arriba.
  - Los demás jugadores siguen dibujándose en el mapa con el aspecto de inicio.
  - Las reglas no se probaron con el emulador.

## D-36. Pantalones y la X de "ninguno"

- **Fecha:** 2026-11-08
- **Estado:** Propuesta
- **Decisión:**
  - Hay **1 pantalón** (`PantsStyle`, "Pantalón Dorado", 45 monedas, poco común). Se compra en la Tienda y sale en los cofres, igual que los demás cosméticos (D-33, D-35). Pestaña **Pantalón** en el Vestuario con "Ninguno" (X roja) y filtro **Pantalones** en la Tienda.
  - Se guardan en el perfil `pants` (id; 0 = ninguno) y `ownedPants`. El pantalón no va en el perfil público: no se ve en la foto de perfil.
  - **Dibujo.** `frente/pantalones/pantalon_<id>.png`. Va **sobre las dos piernas** y debajo de los brazos, sin moverse (en el reposo las piernas están quietas). **Todavía no tiene dibujo de lado**: al caminar por el mapa (y en el reposo de lado) el personaje se ve sin pantalón.
  - Reglas: `pantsPrice`, `isPantsPurchase`, `addsOnePants`, `onlyPantsChange` y `ownedPants` en la cartera; el pantalón puesto tiene que ser 0 o comprado. Una prueba compara el precio de las reglas con el del código. **Hay que publicar las reglas.**
  - **La X de "ninguno":** el espacio "Ninguno" de Accesorios, Cabello y Pantalón se muestra como una **X roja** (`NoneMark`). El primer color de las líneas de color de Ojos, Boca y Cabello (el "sin color": el dibujo original) también lleva una X roja (`ColorStrip.firstIsNone`).
- **Pendientes:**
  - Dibujo de lado del pantalón (muslo y rodilla, como las piernas de `lado/cuerpo/`).
  - Las camisas 13 a 16 se agregaron en D-37.

## D-37. Camisas 13 a 16, cabello atrás y vistas previas

- **Fecha:** 2026-11-08
- **Estado:** Propuesta
- **Decisión:**
  - **Camisas 13 a 16** (de fútbol) agregadas a `ShirtStyle` (ahora 23): 13 y 14, 60 monedas (rara); 15 y 16, 75 (épica). Los nombres ("Camiseta de Fútbol 13"...) son provisionales; se cambian en `shirt_style.dart` (el `id` no cambia). `firestore.rules`: `shirtPrice` con los cuatro precios nuevos.
  - **Parte de atrás del cabello:** en el personaje completo es la **capa más atrás** de todas (debajo del cuerpo, para que no se vea delante del cuello) y se mueve con la cabeza. En la foto de perfil y las vistas previas, que no tienen cuerpo, sigue detrás de la cabeza.
  - **Vistas previas** de la Tienda, los cofres y el Vestuario: la de las camisas recorta solo la camisa (sin brazos ni manos), así se ve más grande y con su detalle; la del pantalón se acercó a la cadera.
  - Los archivos `Camisa_13.png` y `Camisa_14.png` pasaron a minúsculas (en Android los nombres distinguen mayúsculas).
- **Pendiente:** las camisas 6 a 12 del .kra usan capas recortadas ("heredar alfa") que mi lector no replica; por eso no se volvieron a exportar y se conservan los PNG anteriores.

## D-38. Peluca de Payaso (cabello multicolor)

- **Fecha:** 2026-11-08
- **Estado:** Propuesta
- **Decisión:** el cabello 11, **Peluca de Payaso** (`HairStyle.clownWig`), es la versión multicolor de la Nube de Rizos (cabello 2): la misma forma, de frente y de lado, con parches de 8 colores. Es **legendaria** (la mayor rareza), cuesta **300 monedas** (el resto, de 45 a 75) y no se tiñe: trae sus colores. Se compra en la Tienda y sale en los cofres como los demás; `firestore.rules`: `hairPrice` con el 11.
- **Arte:** `frente/cabellos/cabello_11.png` y `lado/cabellos/cabello_11.png` se generaron con un programa a partir del cabello 2 (parches de color con bordes ondulados y sombra suave en el borde), no se dibujaron en Krita. Si luego se dibuja a mano, se reemplazan los dos PNG sin tocar el código.

## D-39. Ícono, pantalla de arranque y nombre de la app

- **Fecha:** 2026-11-09
- **Estado:** Propuesta
- **Decisión:**
  - El ícono de la app sale del logo dibujado en Krita (`Logo.kra`, PT con gorro de fiesta). En iOS es el logo entero (sin transparencia); en Android el ícono adaptativo lleva el color liso del logo de fondo y el logo reducido al frente, para que el círculo no corte el gorro.
  - La pantalla de arranque de Android es el color del logo (`#8DDDFF`) con el logo al centro; en Android 12 o más se configura aparte (`values-v31`).
  - El nombre que se ve bajo el ícono es **Party Tricks** (`android:label` en Android y `CFBundleDisplayName` en iOS; también el título y el manifiesto web). El nombre del paquete de Dart sigue siendo `party_tricks`.
- **Motivo:** el ícono genérico de Flutter y el nombre `party_tricks` no se veían como un producto terminado.
- **Alternativas:** el paquete `flutter_launcher_icons` (una dependencia más para algo que se hace una vez); cambiar el nombre del paquete (rompería todos los imports sin ganar nada).
- **Pendiente:** verlo en un celular real; si se cambia el logo hay que volver a generar los archivos (ver `arte_imagenes.md`).

## D-40. Vista de espalda

- **Fecha:** 2026-11-09
- **Estado:** Propuesta
- **Decisión:**
  - El personaje tiene una **tercera vista, de espalda** (`CharacterView.espalda`), sin cara (no se dibujan ojos, boca ni foto). Sirve para el Vestuario y para el mapa cuando el personaje **sube** por la pantalla (un paso sube si va más arriba que a los lados, `_Walker.isGoingUp`); al bajar o ir de lado se sigue viendo de lado, y quieto, de frente.
  - **Cuerpo:** usa las mismas capas de `frente/cuerpo/` (no hay arte nuevo). **Cabeza:** relleno y línea de la cabeza, sin cara, con el cabello encima. **Accesorios:** se ven igual que de frente, pero van **debajo del cabello**.
  - **Cabello** (`espalda/cabellos/cabello_<id>.png`): cubre la cabeza hasta el borde de abajo (la mayoría) o hasta donde llega en la vista de lado. Los cabellos con parte de atrás (1, 3 y 6) usan esa parte; el flequillo no se usa. El borde de abajo sigue la forma del cabello de lado. **Se generaron con un programa** a partir de los dibujos de frente y de lado: si se dibujan a mano, se reemplazan los PNG.
  - **Pantalones** (`espalda/pantalones/`): los 20 nuevos, sin bragueta ni hebilla y con bolsillos traseros. El dorado usa el de frente. **Camisas** (`espalda/camisas/`): solo las del segundo drop (D-42) tienen espalda propia (`ShirtStyle.hasBackArt`); las demás usan el dibujo de frente.
  - **Animaciones** nuevas en `CharacterClip`: *Reposo de espalda* (como el de frente) y *Caminar de espalda* (`WalkAwayAnimation`: una pierna se levanta y luego la otra, el cuerpo sube y baja y los brazos se mecen al revés). Aparecen solas en la vista previa de animaciones.
  - **Vestuario:** el botón de girar pasa de frente a lado a espalda.
- **Pendiente:** dibujar a mano la espalda de las camisas y los cabellos que se ven raros; el salto (animación) no está hecho.

## D-41. Veinte pantalones nuevos, con frente, lado y espalda

- **Fecha:** 2026-11-09
- **Estado:** Propuesta
- **Decisión:**
  - `PantsStyle` pasa de 1 a **21 pantalones** (ids 2 a 21 nuevos): jeans, bermudas cargo y tropical, deportivo, tres faldas (tutú, Bonnie y colegio de magia) y referencias a la cultura pop (Pitufo, Ogro, Pirata, Camuflado, Clyde, Fontanero, Juego del Calamar, Charro, Padrino, Disco, Mono Amarillo, Payaso y Neón). Los nombres con referencias son provisionales; se cambian en `pants_style.dart` sin tocar el `id`.
  - **Rareza y precio:** común 30 (3), poco común 45 (6), raro 60 (6), épico 75 (4) y legendario 100 (Neón). Están en `firestore.rules` (`pantsPrice`) y una prueba los compara.
  - **Largo** (`PantsCut`): *largo* (cadera, muslo y rodilla de lado), *corto* (cadera y muslo) y *falda* (una sola pieza fija sobre las piernas).
  - **Capas de lado** (`lado/pantalones/pantalon_<id>_cadera|muslo|rodilla.png`): de abajo hacia arriba, el muslo y la pantorrilla del personaje, el pantalón del muslo (arranca en la cadera, sin línea arriba) y el de la rodilla (sin línea arriba, para que la unión no se note). La cadera (cintura y cinturón) va **debajo** del muslo del pantalón; la falda, **encima** de las piernas. La pierna de atrás lleva el pantalón un 14 % más oscuro.
  - El dorado (id 1) sigue sin dibujo de lado.
- **Arte:** los 20 se generaron con un programa (formas tomadas de las capas de las piernas), no se dibujaron en Krita. Si luego se dibujan a mano, se reemplazan los PNG sin tocar el código.

## D-42. Camisetas del segundo drop de Shift's

- **Fecha:** 2026-11-09
- **Estado:** Propuesta
- **Decisión:** cinco camisetas nuevas (`shifts8` a `shifts12`, ids 17 a 21) con los diseños del drop 02: Shift's con el perro (blanca con letras azules, negra roja y negra azul) y "the danger of men's" (blanca y negra, rosa). Las cuatro primeras son épicas (75 monedas) y la última, legendaria (100). Traen estampado delante, la placa militar en la manga y el estampado de atrás en la vista de espalda.
- **Arte:** los estampados se sacaron de los mockups del drop (texto, perro y silueta); las placas de las mangas se dibujaron aparte. De lado solo se ve la placa. Nombres y precios provisionales.
- **Nota:** las camisetas llevan armas dibujadas (uzis y una pistola); conviene revisarlo antes de publicar la app en las tiendas.

## D-43. Caminos del mapa en curvas suaves

- **Fecha:** 2026-11-09
- **Estado:** Propuesta
- **Decisión:** los caminos entre casillas dejan de ser rectas y pasan a **curvas Bézier cúbicas sin quiebres** (`RouteCurves`, `services/map/route_curves.dart`). En cada casilla, la curva que llega y la que sale comparten la misma dirección (el promedio de las dos rectas); en una bifurcación, cada desvío sale con su propia curva. El **dibujo** (`MapPathsPainter`) y la **caminata** (`_Walker`) usan los mismos tramos, y el personaje avanza a **paso parejo** por distancia, no por el parámetro de la curva. Las flechas de elegir camino apuntan hacia donde sale la curva.
- **Ajuste:** el redondeo se cambia con `handle` en `RouteCurves.build` (0,38 por defecto).
- **Aviso:** los archivos del mapa son del área de Brayan; hay que avisarle antes de unir la rama.

## D-44. Vista previa del mapa en administración y filtros de la Tienda

- **Fecha:** 2026-11-09
- **Estado:** Propuesta
- **Decisión:**
  - Administración → Galería → **Mapa con personajes** (`map_preview_screen.dart`): el mapa real con de 1 a 4 personajes (el primero con el aspecto del administrador, los demás de ejemplo) y botones para avanzar casillas. Sirve para ver cómo caminan (de lado y de espalda), cómo se ven quietos y cómo van las curvas. Nada se guarda ni crea una partida.
  - Los **filtros de la Tienda** pasan de botones que ocupaban varias líneas a **una sola fila con scroll**: texto pequeño, el elegido en azul y subrayado, y el ícono de ordenar fijo a la derecha.

## D-45. Notificaciones de mensajes e invitaciones

- **Fecha:** 2026-11-09
- **Estado:** Propuesta
- **Decisión:**
  - La app avisa con una **notificación** cuando un amigo te escribe y cuando te invita a una party. Tocar un mensaje abre ese chat en Amigos. La invitación trae dos botones: **Aceptar** (abre la app, entra a la sala con el código y abre la sala de espera) y **Rechazar** (marca la invitación como vista y rechazada, sin abrir la app).
  - **Cliente** (`services/notifications/`, `widgets/notification_host.dart`): `firebase_messaging` recibe los avisos y `flutter_local_notifications` los muestra con sus botones. Cada celular se registra en `fcmTokens/{token}` con el uid de su dueño. El interruptor de notificaciones de Ajustes los activa y desactiva; al cerrar sesión se borra el código. Con la app abierta, un mensaje avisa salvo que ya tengas ese chat abierto, y las invitaciones no (ya salen como aviso dentro de la app).
  - **Servidor** (`functions/`, Cloud Functions): `notifyMessage` y `notifyInvite` mandan el aviso cuando se crea un mensaje o una invitación. A Android le llega solo datos (la app arma la notificación con sus botones aunque esté cerrada) y a iOS el aviso con su categoría. Los códigos que ya no sirven se borran.
  - **Reglas:** `fcmTokens` (solo a nombre propio, sin lectura desde la app) y el invitado puede marcar `seen` y `declined`.
- **Motivo:** enterarse de mensajes e invitaciones sin tener la app abierta.
- **Pendiente:**
  - **Desplegar** las funciones (`firebase deploy --only functions`, necesita el plan Blaze) y publicar las reglas. Sin la función, solo avisan los mensajes con la app abierta.
  - iOS: subir la clave APNs a Firebase y activar *Push Notifications* y *Background Modes* en Xcode.
  - Probarlo en dos celulares.
  - Se usa `flutter_local_notifications` 22 (la 23 pide una versión del SDK de Android que no compila aquí) y `getToken` de Firebase aunque aparezca como deprecado, porque la función manda con el código FCM de siempre.

## D-46. Tienda al pasar, turno de 40 s y mensaje de "no quedan jugadores"

- **Fecha:** 2026-11-13
- **Estado:** Propuesta
- **Decisión:**
  - **Tienda al pasar por encima:** la tienda del mapa se abre al caer en su casilla **y también al pasar** por ella. De paso, el movimiento se detiene con los pasos que faltan en `stepsLeft` (fase `shopping`); el botón dice **Seguir** y, al tocarlo, el jugador termina de avanzar y se aplica la casilla donde cae. Al caer, el botón sigue diciendo **Terminar**. Cambios en `game_engine.dart` (`_move`, `_afterStep`, `_leaveShop`); sin cambios de esquema ni de reglas.
  - **Turno de 40 s:** a quien no decide en 40 s (lanzar, elegir camino o salir de la tienda) se le salta el turno aunque siga conectado. El conteo lo lleva el `RoomGuard` del anfitrión y se reinicia en cada decisión; `DisconnectionPolicy.turnTimeout` pasa de 30 a 40 s y también es lo que se espera a un desconectado.
  - **Mensaje de "no quedan jugadores":** si todos los demás salieron o llevan 40 s desconectados, se muestra "¡Se acabó la fiesta!" con "Lo sentimos, no quedan jugadores :(" y el botón **Regresar a menú** (`NoPlayersLeftView`). No da premios. Si alguien vuelve antes, el mensaje se quita solo.
- **Motivo:** con 2 tiendas en 42 casillas y entrando solo al caer, cada jugador visitaba una tienda 0,4 veces en una partida de 10 rondas (simulación), y el diamante "Más comprador" era casi un sorteo. Un jugador conectado que no hace nada trababa la partida.
- **Pendiente:**
  - Confirmar los valores de casillas, monedas y precios propuestos en `diseno_juego.md` (6.2 y 8) y pasarlos al código.
  - Con la tienda de paso, las visitas suben; volver a simular y revisar los precios.
  - Probar el turno de 40 s y la pantalla de "no quedan jugadores" con varios celulares.

## D-47. Más efectos en las casillas especiales y menú de Jugar con la tarjeta de la app

- **Fecha:** 2026-11-13
- **Estado:** Propuesta
- **Decisión:**
  - **Efectos especiales:** pasan de 5 a **14** (6 buenos, 6 malos y 2 neutros). Nuevos: Viento a favor, Escudo de regalo, Ítem sorpresa, Diamante de regalo, Cambio de monedas, Dado de 2, Pierdes el turno, Se te cae un ítem y Paga la cuenta de la fiesta. Cada uno tiene **peso** en el sorteo (`PendingEffect.weight`), así los fuertes (diamante, perder el turno) salen menos. Los malos pesan un poco más que los buenos (49 contra 47). La lista, con sus pesos, está en `diseno_juego.md`, sección 6.1.
  - El efecto se sortea al caer y se aplica al lanzar el dado (`GameEngine._roll` y `_applyEffect`). "Pierdes el turno" no lanza el dado y pasa el turno. Los nombres guardados de los cinco efectos de antes no cambian; un efecto que la versión no conoce se ignora al leer la partida.
  - El panel de la partida muestra el efecto pendiente de cada jugador con su nombre (`PendingEffect.title`), en verde, rojo o morado.
  - **Menú de Jugar:** usa `DialogCard` con fondo desenfocado, como los demás diálogos, y sus botones llevan ícono y solo el título. Sin cambios de lógica.
- **Motivo:** las especiales daban siempre uno de 5 efectos y casi ninguno cambiaba la partida; el menú de Jugar era el único diálogo con el estilo básico de Material.
- **Pendiente:** probar en celulares; revisar los pesos al jugar; "Cambio de monedas" y "Pierdes el turno" son los más fuertes y pueden frustrar a quien los recibe.
