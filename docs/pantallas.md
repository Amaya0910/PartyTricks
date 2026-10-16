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

| Campo | Descripción |
|---|---|
| `uid` | Identificador de Authentication |
| `correo` | Para iniciar sesión |
| `nombreUsuario` | Único; lo ven los demás jugadores |
| `codigoAmistad` | Único; para que otros te agreguen |
| `experiencia` | XP acumulada; el nivel se calcula a partir de ella |
| `monedas` | Monedas de la cuenta |
| `diamantes` | Diamantes de la cuenta |
| `cosmeticosDesbloqueados` | Lista de ids de cosméticos |
| `cosmeticosEquipados` | Un cosmético por categoría |
| `consumibles` | Inventario de consumibles de la cuenta: cantidad por tipo (por ejemplo, dados extra del cofre "Dados secretos"). Ver sección 2.9 |
| `fotoRostro` | Ruta en Storage (opcional) |

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
| `jugadores` | Por jugador: posición, monedas, diamantes, efecto pendiente, ítems de partida que tiene (cantidad por tipo) y conteos para los premios finales. Ver sección 2.9 |
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

### 2.9 Ítems y consumibles

Hay dos grupos, con vida y lugar de almacenamiento distintos.

**Catálogo de ítems de partida** (datos fijos, iguales para todos). Cada ítem tiene:

| Campo | Descripción |
|---|---|
| `id` y `nombre` | Por ejemplo: trampa, dado extra, escudo |
| `efecto` | Qué hace (ver `diseno_juego.md`, sección 8) |
| `precio` | En monedas de partida **(por definir)** |
| `estado` | Definido o propuesto |

Ítems definidos: **trampa** y **dado extra de 3, 6 o 9**. El resto (escudo, repetir tirada, barrera, teletransporte, intercambio, imán de monedas, veneno) están propuestos.

**Ítems en una partida** (viven en la partida y desaparecen al terminar):

| Dato | Descripción |
|---|---|
| Ítems que tiene cada jugador | Cantidad por tipo; se descuenta al usarlos |
| Trampas colocadas | Casilla y jugador que la puso (ya está en la entidad Partida) |
| Efectos activos | Dados de 3 o 12 en el siguiente turno, escudo activo, etc. |

**Consumibles de cuenta** (viven en el perfil y pasan entre partidas):

| Dato | Descripción |
|---|---|
| Dados extra | Se obtienen en el cofre **Dados secretos** y se gastan en próximas partidas |
| Mejoras consumibles | Se compran con diamantes en la Tienda **(por definir cuáles)** |

Forma sugerida para el inventario, igual para los dos grupos: un mapa de tipo de ítem a cantidad, por ejemplo `{ "dado_extra_3": 2, "dado_extra_6": 1 }`. Así agregar un ítem nuevo no cambia la estructura.

---

## 3. Modelos en el código

Los modelos viven en `lib/models/`. Hoy existen:

| Archivo | Para qué |
|---|---|
| `app_section.dart` | Secciones de la barra de navegación |
| `loading_state.dart` | Estado de la pantalla de carga |
| `play_option.dart` | Opciones del menú de Jugar |

Los modelos de datos de este documento se agregarán a esa carpeta a medida que se construya cada área.

---

## 4. Pendientes

- [ ] Estructura exacta de las colecciones de Firestore y de los nodos de Realtime Database.
- [ ] Reglas de seguridad (que cada jugador solo lea y modifique lo suyo).
- [ ] Forma de garantizar que el nombre de usuario y el código de amistad sean únicos.
- [ ] Qué se guarda para permitir reconexión a una partida.
- [ ] Cómo entran a una partida los dados extra de la cuenta (¿se eligen antes de empezar o se usan automáticamente?) y si existen dados de 3, 6 y 9 en el cofre.
- [ ] Qué mejoras consumibles se venden con diamantes y qué efecto tienen.
- [ ] Si los ítems de partida que sobran al terminar se pierden (lo más simple, **propuesto**).