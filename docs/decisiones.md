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
