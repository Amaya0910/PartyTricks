# Party Tricks — Requerimientos

> Proyecto de aula · Programación Móvil · Flutter + Firebase
> Equipo: **Isabella Amaya** y **Brayan Vasquez**
> Última actualización: 2026-11-13
> Se deriva de `diseno_juego.md`, `pantallas.md`, `arquitectura.md`, `disconnections.md`, `results_system.md`, `progreso_desarrollo.md` y del informe de seguridad (OWASP Mobile Top 10). Si alguno cambia, se actualiza este documento.

---

## 1. Propósito y alcance

Party Tricks es un juego 2D multijugador por turnos con minijuegos para móvil, dirigido a jugadores de **10 a 27 años**. Los jugadores recorren un mapa lanzando dados, compiten en minijuegos y se disputan diamantes. Fuera de la partida hay cuenta, amigos, chat, tienda y personalización del personaje.

Este documento fija **qué debe hacer** el sistema (requerimientos funcionales, RF) y **qué calidades debe cumplir** (requerimientos no funcionales, RNF).

### 1.1 Cómo leerlo

**Prioridad:** _Alta_ = sin esto no hay juego; _Media_ = importante para la experiencia; _Baja_ = deseable.

**Estado:**

| Marca | Significado |
|---|---|
| ✅ | Implementado |
| 🟡 | Parcial o pendiente de verificar (por ejemplo, falta probarlo en celulares o publicar reglas) |
| ⬜ | Pendiente |

El estado refleja lo registrado en `docs/progreso_desarrollo.md` y en el diseño; no sustituye la verificación en un celular.

---

## 2. Requerimientos funcionales

### 2.1 Cuenta y acceso

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-01 | El sistema debe permitir registrarse con nombre de usuario, correo y contraseña (con confirmación de la contraseña) | Alta | ✅ |
| RF-02 | El sistema debe permitir iniciar sesión con correo y contraseña, y con una cuenta de Google | Alta | ✅ |
| RF-03 | El nombre de usuario y el código de amistad deben ser únicos; la creación del perfil y la reserva de ambos deben ser atómicas | Alta | ✅ |
| RF-04 | La contraseña debe tener mínimo 8 caracteres, con mayúscula, minúscula, número y símbolo | Media | ✅ |
| RF-05 | El jugador debe poder cambiar su nombre de usuario (una vez cada 30 días), su correo y su contraseña | Media | ✅ |
| RF-06 | El jugador debe poder generar un nuevo código de amistad y copiarlo | Baja | ✅ |
| RF-07 | El sistema debe avisar mientras el correo no esté verificado y permitir reenviar el enlace; se puede jugar sin verificar | Media | ✅ |
| RF-08 | El jugador debe poder cerrar sesión (con confirmación) | Alta | ✅ |
| RF-09 | La app debe conservar la sesión iniciada y llevar al jugador directo a la pantalla principal | Alta | ✅ |
| RF-10 | La app debe mostrar Acerca de, Términos y condiciones y Política de privacidad | Media | ✅ |

### 2.2 Personaje, vestuario y foto de perfil

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-11 | El jugador debe poder personalizar su personaje: piel, ojos, boca, camisa, pantalón, cabello y accesorios, con colores donde aplique | Media | ✅ |
| RF-12 | El personaje debe verse de frente, de lado y de espalda, con animaciones de reposo y de caminar | Media | ✅ |
| RF-13 | La foto de perfil debe ser la cabeza del personaje sobre un color de fondo elegido por el jugador (16 colores), visible para los demás | Media | ✅ |
| RF-14 | El jugador debe poder usar, de forma opcional, una foto de su cara (cámara o galería) con editor de encuadre; debe poder apagarla o quitarla | Baja | ✅ |
| RF-15 | Cada cosmético debe tener una rareza (común, poco común, raro, épico o legendario) | Media | ✅ |
| RF-16 | El sistema debe permitir personalizar zapatos y nariz | Baja | ⬜ |
| RF-17 | Los cosméticos deben agruparse en colecciones | Baja | ⬜ |

### 2.3 Tienda del juego y economía de la cuenta

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-18 | La tienda debe vender cosméticos por monedas, con filtro por categoría y orden por recomendado, precio o rareza | Media | ✅ |
| RF-19 | La tienda debe vender cofres por diamantes (50, 100 y 150) que den un cosmético aleatorio que el jugador no tenga, 100 monedas, un dado extra o nada | Media | ✅ |
| RF-20 | El jugador debe poder consultar la probabilidad de cada premio de un cofre antes de comprarlo | Media | ✅ |
| RF-21 | Una compra debe fallar con un mensaje claro si no alcanzan las monedas o los diamantes; el saldo y el inventario se actualizan en la misma transacción | Alta | ✅ |
| RF-22 | Lo comprado debe salir de la tienda y aparecer en el vestuario | Media | ✅ |
| RF-23 | La cuenta debe guardar monedas, diamantes, dados extra, cosméticos desbloqueados y equipados | Alta | ✅ |
| RF-24 | Los dados extra consumibles de la cuenta deben poder usarse dentro de una partida | Media | ⬜ |
| RF-25 | Cada nivel que sube el jugador debe dar un premio (caja sorpresa de cosméticos u otros) | Baja | ⬜ |

### 2.4 Salas y lobby

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-26 | El jugador debe poder crear una sala definiendo número de jugadores (2 a 6), rondas (5 a 25) y si es privada o pública | Alta | ✅ |
| RF-27 | El jugador debe poder unirse a una sala con un código de 6 caracteres | Alta | ✅ |
| RF-28 | El jugador debe poder entrar a una sala pública aleatoria con cupo; si no hay ninguna, el sistema avisa y ofrece crear una | Alta | ✅ |
| RF-29 | La sala de espera debe mostrar el código, los jugadores (el creador marcado) y una cuenta regresiva de 1:30 | Alta | ✅ |
| RF-30 | La partida debe arrancar al llenarse la sala o al terminar la espera con 2 o más jugadores; con menos de 2, la sala se cierra con el mensaje "¡Se ha terminado el tiempo! Invita a tus amigos a jugar" | Alta | ✅ |
| RF-31 | El jugador debe poder salir de la sala de espera | Media | ✅ |
| RF-32 | El jugador debe poder invitar amigos a la sala desde el lobby | Media | ✅ |

### 2.5 Partida y tablero

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-33 | Al empezar, todos lanzan un dado a la vez para definir el orden de juego; el número más alto juega primero y el desempate se resuelve por nombre de usuario | Alta | ✅ |
| RF-34 | En su turno, el jugador debe lanzar un dado (1 a 6) y avanzar esa cantidad de casillas por el mapa | Alta | ✅ |
| RF-35 | El mapa debe ser cíclico, con varios caminos; en una bifurcación el jugador elige el camino | Alta | ✅ |
| RF-36 | Las casillas deben ser positivas (dan monedas), negativas (quitan monedas) o especiales (efecto aleatorio en la siguiente ronda) | Alta | ✅ |
| RF-37 | Debe haber un diamante en una casilla aleatoria del mapa; al tomarlo reaparece en otra | Alta | ✅ |
| RF-38 | El mapa debe poder moverse y ampliarse con gestos y mostrar a todos los jugadores, con la cámara siguiendo al propio | Media | ✅ |
| RF-39 | Si el mapa dibujado no carga, la app debe mostrar un tablero de respaldo para poder seguir jugando | Baja | ✅ |
| RF-40 | Tras cada ronda de movimientos debe jugarse un minijuego aleatorio sorteado por el anfitrión | Alta | ✅ |
| RF-41 | La partida debe durar el número de rondas elegido por el creador | Alta | ✅ |
| RF-42 | El panel del tablero debe mostrar la ronda, las monedas y diamantes de cada jugador y la acción que toca | Media | ✅ |
| RF-43 | Debe existir un tiempo máximo de **40 s** por turno: a quien no decide (esté conectado o no) se le salta el turno | Media | ✅ |

### 2.6 Tiendas e ítems de la partida

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-44 | El mapa debe tener dos tiendas a las que se entra al caer en su casilla **o al pasar por encima**, pagando con monedas de partida | Media | ✅ |
| RF-45 | La tienda de la partida debe vender dado extra de 3, 6 y 9, impulso, trampa, escudo y diamante doble | Media | ✅ |
| RF-46 | Cada jugador debe tener una mochila de ítems con máximo 3 de cada uno | Media | ✅ |
| RF-47 | La trampa debe quitar monedas al jugador que pase por la casilla donde se colocó; el escudo debe anular la próxima trampa o casilla negativa | Media | ✅ |
| RF-48 | Ítems propuestos adicionales: repetir tirada, barrera, teletransporte, intercambio, imán de monedas y veneno | Baja | ⬜ |

### 2.7 Minijuegos

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-49 | Cada minijuego debe mostrar una explicación de 3 segundos con cuenta regresiva antes de empezar | Media | ✅ |
| RF-50 | **Para el Tiempo:** objetivo aleatorio de 4 a 19 s, reloj visible 3 s, primer toque cuenta, límite de 25 s; gana la menor diferencia con el objetivo | Alta | ✅ |
| RF-51 | **Reacción:** espera aleatoria de 2 a 7 s, eliminación por adelantarse, límite de 10 s; gana el menor tiempo | Alta | ✅ |
| RF-52 | **Globo Bomba:** capacidad secreta de 30 a 70, inflar 1 a 3 veces por turno, eliminación al reventar y gana el último; si no infla en 10 s, se infla 1 por él | Alta | ✅ |
| RF-53 | Los empates deben resolverse con 1d6 entre los empatados, repitiendo hasta desempatar; si nadie hace una jugada válida, nadie gana | Media | ✅ |
| RF-54 | El ganador de un minijuego debe recibir monedas y sumar un minijuego ganado | Alta | ✅ |
| RF-55 | Al terminar, todos deben ver el resultado: quién ganó, lo que hizo cada uno y el desempate, si lo hubo | Media | ✅ |

### 2.8 Resultados, diamantes y progresión

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-56 | Al final, el sistema debe entregar 4 diamantes finales: mejor en minijuegos, peor suerte, más rico y más comprador | Alta | ✅ |
| RF-57 | Gana quien tenga más diamantes; en caso de empate, ganan todos los empatados | Alta | ✅ |
| RF-58 | La pantalla de resultados debe mostrar el ganador o empate, lo que el jugador se lleva (XP, monedas y diamantes), la clasificación completa y los diamantes finales | Alta | ✅ |
| RF-59 | Los 3 primeros puestos deben ganar XP según `XP = XP_base(puesto) × mult_jugadores × mult_rondas`; un jugador desconectado recibe 0 | Alta | ✅ |
| RF-60 | El nivel debe calcularse con la curva `xp_siguiente(n) = round(50 + 25 × n^1.5)` | Media | ✅ |
| RF-61 | El XP, las monedas y los diamantes ganados deben sumarse a la cuenta sin contarse dos veces | Alta | ✅ |
| RF-62 | El jugador debe poder ver sus estadísticas: partidas, minijuegos, tiempo y racha, podio, premios finales, tablero, tienda y social | Media | ✅ |

### 2.9 Amigos, chat e invitaciones

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-63 | El jugador debe poder enviar, aceptar, rechazar y cancelar solicitudes de amistad con el código de amistad | Alta | ✅ |
| RF-64 | El sistema debe mostrar la lista de amigos con foto, nombre, nivel, último mensaje y aviso de mensajes sin leer | Media | ✅ |
| RF-65 | El jugador debe poder chatear con sus amigos (texto, máximo 200 caracteres) desde el menú principal | Alta | ✅ |
| RF-66 | El jugador debe poder eliminar amigos, bloquear jugadores y reportar mensajes indicando el motivo; el bloqueo se deshace en Ajustes | Media | ✅ |
| RF-67 | El jugador debe poder invitar a un amigo a una sala; el invitado debe recibir la invitación en el chat y, si está en el menú principal, un aviso emergente | Media | ✅ |
| RF-68 | La app debe enviar notificaciones push de mensajes e invitaciones, activables en Ajustes | Media | 🟡 |
| RF-69 | Debe haber reacciones rápidas (emojis) sobre el personaje durante la partida, con límite de frecuencia | Baja | ⬜ |

### 2.10 Desconexiones y reconexión

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-70 | El sistema debe detectar en tiempo real cuándo un jugador se desconecta | Alta | ✅ |
| RF-71 | Si se desconecta un jugador y quedan 2 o más, la partida debe continuar saltando sus turnos (40 s de espera) sin darle premios | Alta | ✅ |
| RF-72 | Si se desconecta el anfitrión, otro jugador debe tomar ese rol (15 s de espera) sin perder las acciones pendientes | Alta | ✅ |
| RF-73 | Un jugador que vuelve debe conservar su posición, monedas, diamantes y mochila, y poder regresar a la partida desde Inicio | Media | ✅ |
| RF-74 | Cuando solo queda un jugador, debe verse "¡Se acabó la fiesta! Lo sentimos, no quedan jugadores :(" con el botón **Regresar a menú** | Media | ✅ |
| RF-75 | El sistema debe borrar las salas vacías o abandonadas (2 h sin señales) | Media | ✅ |
| RF-76 | Quien sale a mitad de partida debe confirmarlo; sus turnos se saltan y no gana XP ni premios | Media | ✅ |

### 2.11 Ajustes

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RF-77 | El jugador debe poder activar o apagar notificaciones, sonido y efectos de sonido, guardados en el celular | Baja | ✅ |
| RF-78 | El idioma de la app debe ser español; otros idiomas quedan para después | Baja | 🟡 |

---

## 3. Requerimientos no funcionales

### 3.1 Plataforma y compatibilidad

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RNF-01 | La app debe construirse con Flutter para dispositivos móviles (Android como plataforma principal; iOS con los permisos configurados) | Alta | ✅ |
| RNF-02 | La interfaz debe adaptarse a distintos tamaños de pantalla en orientación vertical | Media | 🟡 |
| RNF-03 | La app debe pedir solo los permisos que usa (cámara, galería, notificaciones, internet) | Media | ✅ |

### 3.2 Rendimiento y tiempo real

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RNF-04 | Los cambios en la sala y en la partida deben verse en los demás celulares casi al instante (flujos en tiempo real de Firebase) | Alta | ✅ |
| RNF-05 | Los tiempos de espera deben compararse con la hora del servidor, para que no dependan del reloj del celular | Media | ✅ |
| RNF-06 | La foto de la cara debe reducirse (JPEG de 256 × 256, máximo 60 000 caracteres) para no recargar la base de datos | Media | ✅ |
| RNF-07 | Los minijuegos y el tablero deben moverse con fluidez, sin depender de un motor externo, salvo que un minijuego lo requiera | Media | 🟡 |

### 3.3 Disponibilidad y fiabilidad

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RNF-08 | Una partida no debe quedarse trabada por la desconexión de un jugador o del anfitrión | Alta | ✅ |
| RNF-09 | El estado completo de la partida debe guardarse en Firebase, no solo en el celular del anfitrión, para permitir reconexión y cambio de anfitrión | Alta | ✅ |
| RNF-10 | Las operaciones que tocan varios datos (registro, compras, cofres, cambio de nombre, cambio de anfitrión) deben ser transacciones atómicas | Alta | ✅ |
| RNF-11 | Una partida no debe contarse dos veces en las estadísticas ni en el XP | Alta | ✅ |
| RNF-12 | Los tiempos de desconexión deben ser configurables (`DisconnectionPolicy`) | Baja | ✅ |

### 3.4 Seguridad y privacidad

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RNF-13 | La contraseña debe gestionarla Firebase Authentication y no guardarse en la base de datos del juego | Alta | ✅ |
| RNF-14 | Las reglas de Firestore y Realtime Database deben limitar a cada jugador a leer y modificar lo suyo; todo lo demás queda cerrado | Alta | ✅ |
| RNF-15 | Las reglas de seguridad deben tener pruebas automáticas en el emulador (`rules_test/`) | Media | ✅ |
| RNF-16 | El perfil público no debe exponer el correo; los campos del perfil público, el chat, las invitaciones y los reportes deben validarse en las reglas | Alta | ✅ |
| RNF-17 | Solo se aceptan fotos de perfil por HTTPS desde `lh3.googleusercontent.com` | Media | ✅ |
| RNF-18 | La app no debe sacar sus datos en copias de seguridad ni escribir registros de depuración en la versión release | Media | ✅ |
| RNF-19 | La versión release debe firmarse con una llave propia y ofuscarse; la compilación debe fallar si falta la llave | Media | ✅ |
| RNF-20 | La app no debe declarar permisos que no usa (se quitó el micrófono) | Media | ✅ |
| RNF-21 | Los premios de la partida no deben poder falsificarse desde un celular modificado (H-02) | Alta | ⬜ |
| RNF-22 | Los datos de la sala (`players`) deben protegerse contra escrituras indebidas (H-07) | Alta | ⬜ |
| RNF-23 | Las dependencias del backend deben estar libres de vulnerabilidades conocidas (H-11) | Media | ⬜ |
| RNF-24 | Las llaves de Firebase deben restringirse y activarse App Check (H-12) | Media | ⬜ |
| RNF-25 | Se debe exigir el correo verificado para las acciones sensibles (H-13) | Media | ⬜ |
| RNF-26 | Las fotos de la cara deben tener moderación, por el público menor de edad | Media | ⬜ |
| RNF-27 | El jugador debe poder reportar y bloquear a otros jugadores | Media | ✅ |

> Los ID H-xx son los hallazgos del informe de seguridad (OWASP Mobile Top 10, 2024). H-01, H-03, H-04, H-05, H-06, H-08, H-09 y H-10 están corregidos; los demás tienen plan de corrección en el informe.

### 3.5 Usabilidad

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RNF-28 | La navegación debe ser una barra inferior de 5 secciones (Tienda, Vestuario, Inicio, Stats, Amigos) que conserva el estado de cada una | Media | ✅ |
| RNF-29 | La interfaz debe seguir el mockup de Figma y un tema de colores único (`AppColors`) | Media | ✅ |
| RNF-30 | Los textos y mensajes de error deben estar en español, claros y adecuados para jugadores desde los 10 años | Media | ✅ |
| RNF-31 | Las acciones destructivas (cerrar sesión, eliminar amigo, bloquear, salir de una partida) deben pedir confirmación | Media | ✅ |
| RNF-32 | Cada minijuego debe poder entenderse en 3 segundos y durar menos de un minuto | Media | ✅ |

### 3.6 Mantenibilidad y calidad

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RNF-33 | El código debe organizarse en capas (pantallas → controladores → servicios → Firebase) y en las carpetas `controllers`, `models`, `screens`, `services` y `widgets` | Alta | ✅ |
| RNF-34 | Las reglas del juego deben vivir en código independiente de Firebase y de la interfaz, para probarlas solas | Alta | ✅ |
| RNF-35 | Los servicios deben entregarse por interfaz para poder reemplazarlos por versiones falsas en las pruebas (Riverpod) | Media | ✅ |
| RNF-36 | Debe haber pruebas unitarias, de integración y de widgets (795 pruebas pasando al 2026-11-09) | Alta | ✅ |
| RNF-37 | El equipo debe trabajar con ramas por área y documentar las decisiones en `decisiones.md` | Media | ✅ |

### 3.7 Escalabilidad y portabilidad

| ID | Requerimiento | Prioridad | Estado |
|---|---|---|---|
| RNF-38 | Los valores del juego (XP base, curva de niveles, tiempos, precios) deben poder ajustarse sin reescribir la lógica | Baja | ✅ |
| RNF-39 | Si el juego se publica, el cálculo de la partida debe pasar del celular del anfitrión a Cloud Functions, para evitar trampas | Media | ⬜ |

---

## 4. Restricciones

- Backend sobre **Firebase** (Authentication, Cloud Firestore, Realtime Database, Cloud Messaging y Cloud Functions). Las Cloud Functions necesitan el plan Blaze.
- Gestor de estado: **Riverpod**.
- Proyecto de aula: el celular del anfitrión hace de servidor de la partida (limitación conocida en `arquitectura.md`, sección 9).
- Equipo de dos personas, con entrega académica en noviembre de 2026.

---

## 5. Pendientes que afectan a los requerimientos

- [ ] Reglas que faltan por publicar en Firebase (`firebase deploy`) y probar con varios celulares (ver `progreso_desarrollo.md`).
- [x] Tiempo máximo por turno: 40 s (RF-43).
- [ ] Confirmar la propuesta de casillas, monedas y precios (`diseno_juego.md`, secciones 6.2 y 8) y pasarla al código.
- [ ] Moderación del chat y de las fotos de la cara (RNF-26).
- [x] Mensaje de "no quedan jugadores" (RF-74).
- [ ] Hallazgos abiertos del informe de seguridad (RNF-21 a RNF-25).

---

## 6. Trazabilidad

| Grupo | Documento de referencia |
|---|---|
| RF-01 a RF-10 | `pantallas.md` (secciones 1.1 y 8), `decisiones.md` (D-16, D-17) |
| RF-11 a RF-17 | `pantallas.md` (secciones 5 y 5.1), `arte_imagenes.md`, `decisiones.md` (D-29 a D-36, D-40, D-41) |
| RF-18 a RF-25 | `pantallas.md` (sección 4), `diseno_juego.md` (secciones 7 y 8.1) |
| RF-26 a RF-32 | `diseno_juego.md` (sección 4), `pantallas.md` (sección 3.1) |
| RF-33 a RF-43 | `diseno_juego.md` (secciones 5 y 6), `pantallas.md` (sección 3.2) |
| RF-44 a RF-48 | `map_shop_items.md`, `diseno_juego.md` (sección 8) |
| RF-49 a RF-55 | `diseno_juego.md` (sección 9), `decisiones.md` (D-26) |
| RF-56 a RF-62 | `results_system.md`, `diseno_juego.md` (secciones 10 y 11), `pantallas.md` (sección 6) |
| RF-63 a RF-69 | `pantallas.md` (sección 7), `decisiones.md` (D-45) |
| RF-70 a RF-76 | `disconnections.md` |
| RNF-04 a RNF-12, RNF-33 a RNF-37 | `arquitectura.md`, `disconnections.md`, `progreso_desarrollo.md` |
| RNF-13 a RNF-27 | Informe de seguridad (OWASP), `database.rules.json`, `firestore.rules`, `rules_test/` |
