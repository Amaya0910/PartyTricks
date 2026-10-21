# Party Tricks — Modelos de datos

> Proyecto de aula · Programación Móvil
> Borrador **(propuesto)**: sale de `diseno_juego.md` y `arquitectura.md`. Los campos exactos y su ubicación en Firebase se definen en `chore/firebase-setup`.

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
| `codigoAmistad` | `friendCode` | Único; 6 caracteres sin letras que se confunden (O/0, I/1); para que otros te agreguen |
| `experiencia` | `experience` | XP acumulada, empieza en 0; el nivel se calcula a partir de ella |
| `monedas` | `coins` | Monedas de la cuenta, empiezan en 0 |
| `diamantes` | `diamonds` | Diamantes de la cuenta, empiezan en 0 |
| `cosmeticosDesbloqueados` | _(por construir)_ | Lista de ids de cosméticos |
| `cosmeticosEquipados` | _(por construir)_ | Un cosmético por categoría |
| `dadosExtra` | _(por construir)_ | Dados extra consumibles obtenidos en el cofre "Dados secretos"; se gastan en próximas partidas |
| `fotoRostro` | _(por construir)_ | Ruta en Storage (opcional) |

#### Colecciones de Firestore de la cuenta

| Colección | Documento | Contenido | Para qué |
|---|---|---|---|
| `users` | `{uid}` | El perfil de la tabla anterior | Datos del jugador |
| `usernames` | `{nombre en minúsculas}` | `uid` y `email` | Reservar el nombre de usuario (único) y permitir iniciar sesión con él (ver D-17) |
| `friendCodes` | `{código}` | `uid` | Reservar el código de amistad (único) |

El perfil y las dos reservas se crean en la misma transacción al registrarse. Si el nombre o el código ya existen, la transacción falla y no se guarda nada.

### 2.2 Cosmético

| Campo | Descripción |
|---|---|
| `id` | Identificador |
| `categoria` | Camisa, Pantalón, Zapatos, Cabello, Nariz, Ojos o Boca |
| `nombre` y `descripcion` | Texto que se muestra en la tienda |
| `precio` | En monedas o diamantes |

### 2.3 Cofre

| Campo | Descripción |
|---|---|
| `id` y `nombre` | Cofre Básico, Cofre Party y el cofre **Dados secretos** (donde se compran dados extra) |
| `precio` | 50, 100 o 150 según el mockup **(por definir cuál cofre cuesta cuánto)** |
| `probabilidades` | Premios posibles de cada cofre; en Básico y Party: dado extra, monedas, cosmético aleatorio o nada (deben sumar 100 %) |

### 2.4 Amistad y chat

| Entidad | Campos |
|---|---|
| Amistad | Los dos jugadores y la fecha en que se agregaron |
| Mensaje | Remitente, texto y fecha (se ordenan por fecha) |

### 2.5 Sala

| Campo | Descripción |
|---|---|
| `codigo` | Código para entrar a una sala privada |
| `creador` | Jugador que hace de "servidor" |
| `tipo` | Pública o privada |
| `maxJugadores` | Entre 2 y 6 |
| `rondas` | Entre 5 y 25 |
| `estado` | Esperando, en juego o terminada |
| `jugadores` | Lista con su presencia (conectado o no) |

### 2.6 Partida

| Campo | Descripción |
|---|---|
| `ordenTurnos` | Resultado de la tirada inicial, con el desempate por nombre |
| `rondaActual` y `turnoActual` | Dónde va la partida |
| `jugadores` | Por jugador: posición, monedas, diamantes, efecto pendiente, ítems y conteos para los premios finales |
| `casillas` | Tipo de cada casilla (positiva, negativa o especial) |
| `casillaDiamante` | Casilla donde está el diamante |
| `trampas` | Casillas con trampa colocada y quién la puso |

Conteos que se guardan para los **diamantes finales**: minijuegos ganados, casillas negativas pisadas, monedas al final y compras hechas.

### 2.7 Resultado de partida

| Campo | Descripción |
|---|---|
| `puesto` | 1º, 2º, 3º y los demás |
| `experienciaGanada` | Según la fórmula de `diseno_juego.md` (sección 11.1) |
| `monedasYDiamantes` | Lo que sobra y pasa a la cuenta |

Un jugador desconectado recibe 0 de experiencia, monedas y diamantes.

### 2.8 Estadísticas del jugador

Contadores para la pantalla de Stats: partidas ganadas y perdidas, máximo de diamantes y de monedas en una partida, minijuegos ganados y perdidos, mejor puntaje, tiempo en la app, jugando y en minijuegos, y rachas (actual y máxima).

---

## 3. Modelos en el código

Los modelos viven en `lib/models/`. Hoy existen:

| Archivo | Para qué |
|---|---|
| `app_section.dart` | Secciones de la barra de navegación |
| `loading_state.dart` | Estado de la pantalla de carga |
| `play_option.dart` | Opciones del menú de Jugar |
| `room.dart` | Sala de juego: configuración, jugadores y cuándo arranca o se cierra |
| `user_profile.dart` | Perfil del jugador (correo, nombre de usuario, código de amistad, experiencia, monedas y diamantes) |
| `auth_form_state.dart` | Estado de los formularios de inicio de sesión y registro (cargando y mensaje de error) |

Los modelos de datos de este documento se agregarán a esa carpeta a medida que se construya cada área.

---

## 4. Pendientes

- [ ] Estructura exacta de las colecciones de Firestore y de los nodos de Realtime Database (la de la cuenta ya está en 2.1).
- [ ] Reglas de seguridad (que cada jugador solo lea y modifique lo suyo). En `usernames`, permitir leer solo por nombre exacto y no listar (ver `decisiones.md`, D-17).
- [x] Forma de garantizar que el nombre de usuario y el código de amistad sean únicos (colecciones `usernames` y `friendCodes` con transacción; ver D-16).
- [ ] Qué se guarda para permitir reconexión a una partida.