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
- **Decisión:** ramas `main` y `develop`, una rama por tarea (`feature/...`, `docs/...`, `fix/...`), commits con prefijo y Pull Request revisado por la otra persona.
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
  - Escribir las reglas de seguridad antes de que venza el modo de prueba (30 días).
  - Storage pide el plan Blaze (de pago); se decide cuando llegue `feature/wardrobe-avatar`.
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
- **Provisional:** mientras no exista `feature/auth`, las salas usan un usuario anónimo de Firebase con el nombre "Jugador XXXX". Se cambia en `room_providers.dart` cuando esté el inicio de sesión. Al arrancar la partida se muestra un mensaje; el tablero llega en `feature/board-turns`.
- **Pendientes:** reglas de seguridad de Realtime Database, borrar salas viejas y qué pasa si el creador se sale (va en `feature/disconnections`).

## D-15. Partida en vivo y pantalla del tablero

- **Fecha:** 2026-10-18
- **Estado:** Propuesta (por confirmar con Isabella)
- **Decisión:** el estado de la partida se guarda en `rooms/{id}/game` y solo lo escribe el teléfono del creador (anfitrión). Los jugadores mandan sus acciones a `rooms/{id}/actions`; el anfitrión las aplica con el motor en orden y borra cada una en la misma escritura. Las acciones fuera de turno se ignoran.
- **Provisional:** el tablero se dibuja en una cuadrícula de 9×8 (camino principal por el borde, caminos alternos por dentro) hasta tener el dibujo de Isabella. Como aún no hay minijuegos, el creador tiene un botón "Simular minijuego" que sortea al ganador. La pantalla de resultados llega en `feature/results-xp`.
- **Pendientes:** salir a mitad de partida y cambio de anfitrión (`feature/disconnections`).