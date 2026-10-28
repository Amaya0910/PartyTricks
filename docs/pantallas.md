# Party Tricks — Pantallas y navegación

> Proyecto de aula · Programación Móvil
> Basado en el mockup de Figma y en el código actual de `lib/screens/`.
> Complementa a `diseno_juego.md` (sección 14) y `arquitectura.md`.
> Última actualización: 2026-10-27

**Mockup en Figma:** _(pegar aquí el enlace)_

---

## 1. Navegación general

La app arranca en una **pantalla de carga** (`AppGate` → `LoadingScreen`). Después, `AppGate` revisa si hay una sesión iniciada: si no la hay muestra la pantalla de **acceso**, y si la hay muestra la estructura principal (`MainShellScreen`): la sección activa arriba y una **barra de navegación inferior** con 5 secciones.

```
Carga  →  ¿Hay sesión?
            ├── No  →  Acceso (Inicio de sesión ⇄ Registro)  →  MainShellScreen
            └── Sí  →  MainShellScreen
                         ├── Tienda
                         ├── Vestuario
                         ├── Inicio      (sección inicial)
                         │     └── Jugar → Sala de espera → Tablero
                         ├── Stats
                         └── Amigos
```

- La barra conserva el estado de cada sección al cambiar de pestaña.
- El orden de las secciones está definido en `lib/models/app_section.dart`.
- Los colores de la barra salen del tema (`lib/theme/`).

### 1.1 Acceso (inicio de sesión y registro)

Archivo: `auth_screen.dart`. Es una sola tarjeta que **da la vuelta** para mostrar la otra cara; lo que el jugador escribió en cada cara se conserva al voltear.

| Cara | Campos | Enlace para voltear |
|---|---|---|
| Inicio de sesión | Correo o nombre de usuario (sin distinguir mayúsculas) y contraseña | ¿Aun no te registras? |
| Registrarse | Nombre de usuario, correo, contraseña y repetir la contraseña | ¿Ya tienes una cuenta? |

- El botón **Entrar a la party** inicia sesión o crea la cuenta. Si sale bien, la app pasa sola a `MainShellScreen`.
- Las contraseñas tienen un **ojo** para mostrarlas u ocultarlas.
- Los errores (datos inválidos, nombre en uso, contraseña incorrecta) salen en rojo dentro de la tarjeta.
- El fondo es el mismo dibujo de las demás pantallas (`Fondo_Principal.png`), bajado para que solo se vean las nubes (se ajusta con `_hiddenFraction` en `auth_screen.dart`).
- Los colores están en `AppColors`, en la sección "Inicio de sesión y registro".
- Las reglas de los datos y cómo se guardan la cuenta y el perfil están en `decisiones.md`, D-16 y D-17.

---

## 2. Pantallas principales (barra de navegación)

| Sección | Archivo | Estado | Contenido según el mockup |
|---|---|---|---|
| Inicio | `home_screen.dart` | En desarrollo | Cabecera del jugador, personaje y botón **Jugar** |
| Tienda | `shop_screen.dart` | En desarrollo | Tienda de Tricks: cofres (50, 100, 150) y cosméticos con precio |
| Vestuario | `wardrobe_screen.dart` | En desarrollo | Foto del rostro y categorías: Camisa, Pantalón, Zapatos, Cabello, Nariz, Ojos, Boca |
| Stats | `stats_screen.dart` | En desarrollo | Estadísticas de partidas, minijuegos y tiempo |
| Amigos | `friends_screen.dart` | En desarrollo | Solicitudes, lista de amigos, chat e invitaciones |

**Estado:** _Base_ = pantalla provisional con un texto; _En desarrollo_ = ya tiene interfaz, pero faltan datos o funciones.

---

## 3. Inicio

- **Cabecera del jugador:** foto de perfil, nombre de usuario, monedas y diamantes. Los datos salen del perfil del jugador con la sesión iniciada.
- **Personaje:** el rostro armado con los cosméticos equipados (por ahora, un ícono provisional).
- **Botón Jugar:** abre un menú emergente con tres opciones.

### Menú de Jugar

| Opción | Qué hace | Estado |
|---|---|---|
| Crear Party | Abre "Alista tu party": el creador define jugadores (2 a 6), rondas (5 a 25) y si la sala es privada o pública. Luego pasa a la sala de espera | Listo |
| Unirse a Party | Pide un código de sala de 6 caracteres y entra a la sala de espera | Listo |
| Juego Random | Entra a una sala pública con cupo. Si no hay ninguna, avisa "No hay salas públicas libres, crea una" | Listo |

### 3.1 Sala de espera (lobby)

Archivo: `lobby_screen.dart`.

- Muestra el **código de la sala** en cuadritos (por ejemplo ABC-234), los **jugadores** con su espacio (el creador lleva una estrella y el propio jugador aparece como "(tú)") y la **cuenta regresiva de 1:30**.
- El teléfono del creador decide cuándo empieza o se cierra la sala (ver `diseno_juego.md`, sección 4.3).
- Si se cierra por falta de jugadores, muestra "¡Se ha terminado el tiempo! Invita a tus amigos a jugar" y el botón **Regresar a menú**.
- El botón **Invitar a amigos** abre la lista de amigos con casillas (los que ya están en la sala no aparecen). Cada invitado recibe la invitación en el chat y, si está en el menú principal, un aviso emergente (ver 7.3).
- El botón **Salir** saca al jugador de la sala.
- Los jugadores aparecen con su nombre de usuario real.
- Cuando la sala arranca, todos pasan al tablero.

### 3.2 Tablero de juego

Archivos: `board_screen.dart`, `lib/widgets/map/` (mapa dibujado) y `board_view.dart` (tablero de cuadritos de respaldo).

- Arriba, el **mapa dibujado** (ver `decisiones.md`, D-25), que ocupa casi toda la pantalla:
  - Fondo, caminitos de piedra entre casillas, plataformas de pasto con su marca (inicio, negativa, especial), tiendas detrás de su casilla y el diamante.
  - Se puede **mover y hacer zoom**. La cámara sigue a tu personaje cuando camina.
  - Se ven **todos los jugadores** (por ahora su foto en un círculo con su color). Avanzan **saltando de casilla en casilla**; si varios están en la misma casilla, se ponen uno al lado del otro.
  - Al empezar se ven unas 5 casillas de ancho; al alejar del todo, el mapa llena la pantalla.
  - En una **bifurcación**, en tu turno, aparecen **dos flechas** sobre los caminos; tocas la del camino que quieres.
  - Si el mapa no carga o le faltan casillas, se muestra el tablero de cuadritos de antes para que se pueda seguir jugando.
- Abajo, un panel con la **ronda actual**, la lista de jugadores (monedas y diamantes) y lo que toca hacer:
  - **Lanzar dado** (cuando es tu turno).
  - "Toca una flecha en el mapa para elegir el camino" (cuando llegas a una bifurcación). Con el tablero de respaldo salen los botones **Seguir** y **Atajo**.
  - **Simular minijuego** (solo el creador; provisional hasta tener minijuegos).
- Al terminar la última ronda se muestra el ganador en el panel. La pantalla de resultados llega en `feature/results-xp`.
- Todavía no se puede salir a mitad de partida (llega con `feature/disconnections`).
- Pendiente: monedas animadas en las casillas positivas, minimapa, puentes, decoraciones y las hojas de animación del personaje.

---

## 4. Tienda

Archivo: `shop_screen.dart`.

- Encabezado **Tienda de Tricks** con la franja **COFRES**.
- Tres cofres con su precio en **diamantes**: Cofre Básico (50), Cofre Party (100) y Cofre Diamante (150, nombre provisional; el mockup lo repite como "Cofre Party").
- Al tocar un cofre se abre una ventana con sus **probabilidades** de premio (cosmético aleatorio, nada, 100 monedas o dado extra) y el botón **Comprar**.
- Si no alcanzan los diamantes, la ventana muestra el mensaje de error; si se compra, aparece un aviso con el premio.
- Debajo de los cofres está la lista de ítems. Por ahora muestra "Aún no hay ítems en la tienda"; los cosméticos con nombre, descripción, precio y botón **Comprar** llegan después.
- Las reglas de la compra están en `decisiones.md`, D-18.

---

## 5. Vestuario

Archivo: `wardrobe_screen.dart`.

- Arriba, el personaje (ícono provisional) y el botón **Foto** para usar una foto propia (**opcional**). Por ahora solo muestra "La cámara llega pronto".
- En el medio, la barra de **categorías**: Camisa, Pantalón, Zapatos, Cabello, Nariz, Ojos y Boca. Se desplaza si no caben.
- Abajo, una cuadrícula con los cosméticos que el jugador ya tiene en la categoría elegida. Si no tiene ninguno, muestra un mensaje ("Aún no tienes ninguna camisa", etc.).
- Provisional: los cosméticos son un mapa fijo en el código (solo "Camisa 1"). Se reemplazan por los cosméticos desbloqueados del perfil (ver `decisiones.md`, D-19).

---

## 6. Stats

Archivo: `stats_screen.dart`.

- Arriba, la misma **cabecera del jugador** que en Inicio.
- Debajo, **todas las tarjetas en una lista** que se recorre hacia abajo (sin pestañas). Las tres primeras son las del mockup; las demás repiten sus colores en orden: azul, azul oscuro y morado (`AppColors`, sección "Estadísticas"; solo el azul oscuro es un color nuevo).

| Tarjeta | Datos | Estado |
|---|---|---|
| Partidas | Ganadas, perdidas, porcentaje de ganadas, máximo de diamantes y de monedas en una partida | Listo |
| Minijuegos | Ganados, perdidos, porcentaje de ganados, máximo de ganados en una partida y mejor puntaje | Listo (el puntaje queda en 0 hasta tener minijuegos con puntaje) |
| Tiempo | En la app, jugando y en minijuegos (en minutos), racha actual y máxima (en días) | Listo |
| Podio | Partidas jugadas, primer, segundo y tercer lugar, empates, victorias seguidas y máximo de victorias seguidas | Listo |
| Premios finales | Veces que ganó cada diamante final (rey de los minijuegos, peor suerte, el más rico, mayor comprador) y el total | Listo |
| Detalle de partidas | Como anfitrión, públicas, privadas, rondas jugadas, partida más larga, promedio de diamantes, monedas y diamantes ganados | Listo |
| Tablero | Dados lanzados, promedio del dado, veces con el número máximo, casillas positivas, negativas y especiales, caminos normales, atajos, vueltas, diamantes del mapa y compras en tiendas del mapa | Listo (las compras llegan con `feature/map-shop-items`) |
| Minijuegos por tipo | Favorito, más ganado y tipos jugados | Preparado: se llena cuando existan minijuegos |
| Tienda | Cofres abiertos por tipo y en total, diamantes gastados y premios obtenidos | Listo |
| Social | Compañero más frecuente, partidas con amigos, invitaciones enviadas y aceptadas, mensajes enviados | Compañero listo; lo demás llega con `feature/friends-chat` |

- Los datos salen de `stats/{uid}` en vivo: se actualizan solos.
- **Cuándo se guardan:**
  - **Partida:** al llegar al final, cada jugador guarda la suya desde `BoardScreen`. Una partida no se cuenta dos veces.
  - **Cofres:** en la misma transacción de la compra.
  - **Tiempo en la app:** mientras la app está en primer plano (`AppUsageTracker`); se guarda cada minuto y al pasar a segundo plano.
  - **Racha:** cuenta los días seguidos en que se abre la app.
- Las etiquetas y el formato de cada tarjeta están en `StatsPresenter`. Los decimales llevan coma (3,5) y los datos que aún no existen se muestran con una raya (—).
- Las reglas están en `decisiones.md`, D-21.

---

## 7. Amigos

Archivos: `friends_screen.dart` y `chat_view.dart`. La lista y el chat van en la misma tarjeta, dentro de la pestaña Amigos, como en el mockup. Los colores están en `AppColors`, sección "Amigos y chat" (todos reutilizan colores que ya existían).

### 7.1 Tus amigos

- Cabecera azul **Tus amigos** y, debajo, **Tu código** con un botón para copiarlo.
- **Solicitudes (N):** las que te enviaron, con Aceptar (✓) y Rechazar (✗).
- **Amigos:** foto, nombre, nivel (corona) y el último mensaje. Un punto azul avisa si hay mensajes sin leer. El chat más reciente va primero.
- **Enviadas:** tus solicitudes que aún no aceptan, con la opción de cancelarlas.
- Botón **+**: pide el código de amistad del otro jugador (mismo diálogo de 6 cuadritos que "Unirse a Party").
  - Si el otro ya te había enviado una solicitud, quedan como amigos de una vez.
  - Mensajes: código no válido, tu propio código, no existe, ya son amigos, ya enviaste la solicitud.
- El botón atrás del celular cierra el chat antes de salir de la app.

### 7.2 Chat

- Cabecera verde con la flecha para volver, la foto, el nombre, el nivel y el menú **⋮**.
- Mensajes: los tuyos a la derecha en azul y los del amigo a la izquierda en gris, con la hora (`14:05`, o `27/10 14:05` si no es de hoy).
- Campo **Presiona para escribir**, de máximo 200 caracteres. Se marca como leído mientras está abierto.
- Menú ⋮:
  - **Eliminar amigo** (pide confirmación).
  - **Bloquear** (pide confirmación): deja de ser amigo y ya no puede escribirte, enviarte solicitudes ni invitarte. Se desbloquea en Ajustes.
  - **Reportar**: se elige el motivo y se guarda para que lo revise un adulto o el docente.
- El chat solo está en el menú principal, no dentro de las partidas.

### 7.3 Invitaciones a una party

- Se envían desde **Tu party** (sala de espera) con **Invitar a amigos**.
- Llegan como mensaje del chat con un botón que cambia según la sala: **Unirse**, **La party ya empezó** o **La party se cerró**. Quien invita ve "Invitación enviada".
- Además, sale un aviso emergente **¡Te invitaron!** con Unirse y Ahora no. Solo si el invitado está en el menú principal (no en una sala ni en una partida) y la party aún espera jugadores.
- Al unirse, entra a la sala de espera como con un código.

---

## 8. Cuenta y configuración

Se abre al tocar la foto de perfil en **Inicio** o en **Stats** (ver `decisiones.md`, D-23). Botón **Volver** arriba a la izquierda y, si falta, el aviso de verificar el correo.

| Bloque | Contenido |
|---|---|
| Tu código | Los 6 caracteres del código de amistad, con **Copiar** (al portapapeles) y **Recargar** (pide confirmación y crea uno nuevo) |
| Cuenta | Nombre de usuario (se cambia una vez cada 30 días), correo (pide la contraseña actual y envía un enlace al correo nuevo) y **Cambiar contraseña**. Las cuentas que solo usan Google no ven el cambio de contraseña ni de correo |
| Preferencias | Notificaciones, sonido y efectos de sonido (se guardan en el celular) e idioma (por ahora solo español) |
| Más opciones | Acerca de, Términos y condiciones, Política de privacidad, Jugadores bloqueados y **Cerrar sesión** (pide confirmación) |

### 8.1 Cambiar contraseña

Tarjeta con cabecera morada **CAMBIAR CONTRASEÑA**: contraseña actual, nueva y confirmación, cada una con el ojo para mostrarla. Abajo, la ayuda (mínimo 8 caracteres, con mayúscula, minúscula, número y símbolo; ver D-16) y el botón verde **Confirmar**. Los errores salen sobre el botón.

### 8.2 Textos legales

Acerca de, Términos y condiciones y Política de privacidad se muestran en una pantalla con secciones. Los textos están en `lib/models/legal_document.dart`.

### 8.3 Jugadores bloqueados

Lista de los jugadores que bloqueaste, con su foto y nombre, y el botón **Desbloquear**. Desbloquear no los vuelve amigos: hay que enviar otra solicitud.

### 8.4 Verificación del correo e inicio con Google

- **Aviso de verificación:** en Inicio y en Ajustes, mientras el correo no esté verificado. Botones **Reenviar** y **Ya lo verifiqué**. Se puede jugar sin verificar.
- **Continuar con Google:** botón debajo de **Entrar a la party** en la tarjeta de inicio de sesión.
- **Elige tu nombre:** la primera vez que alguien entra con Google, una tarjeta le pide el nombre de usuario (botón **Entrar a la party**) o le deja **Usar otra cuenta**.

---

## 9. Pantallas por diseñar o construir

Pantallas que se deducen del diseño del juego y que **aún no aparecen en el mockup** **(propuesto)**:

- [x] Registro e inicio de sesión (diseñados en Figma y construidos; ver 1.1).
- [x] Lobby de sala (espera de 1:30 minutos; ver 3.1).
- [x] Tablero de juego y turnos (provisional; ver 3.2).
- [ ] Minijuego (puede usar Flame si es de tiempo real; ver `decisiones.md`, D-11).
- [ ] Resultados de la partida.
- [ ] Mensaje "Lo sentimos, no quedan jugadores :(" con el botón **[Regresar a menú]**.
- [ ] Tienda de ítems (cosméticos a la venta).
- [x] Ajustes: cuenta, preferencias, cambio de contraseña, textos legales y bloqueados (ver sección 8).