# Party Tricks — Diseño del juego

> Proyecto de aula · Programación Móvil · Flutter + Firebase
> Estado: borrador 2. Lo marcado como **(por definir)** aún no está decidido y lo marcado como **(propuesto)** es una sugerencia pendiente de confirmar por el equipo.

---

## 1. Resumen

Party Tricks es un juego 2D multijugador por turnos con minijuegos, pensado para niños, adolescentes y adultos jóvenes (**10 a 27 años**). Los jugadores recorren un mapa cíclico lanzando dados, ganan o pierden monedas según la casilla en la que caen, compiten en minijuegos cortos y se disputan diamantes. Gana quien tenga más diamantes al final de la partida.

La jugabilidad es medianamente compleja: combina azar (dados, casillas), decisión (caminos, compras) y habilidad (minijuegos). Fuera de las partidas hay una capa social y de progresión: cuenta, amigos, chat, personalización del personaje y tiendas.

---

## 2. Público objetivo

| Aspecto | Detalle |
|---|---|
| Edad | 10 a 27 años |
| Plataforma | Móvil (Flutter) |
| Modalidad | Multijugador en salas, con cuentas y amigos |

---

## 3. Cuenta del jugador

### 3.1 Datos de la cuenta

| Dato | Descripción |
|---|---|
| Correo | Para iniciar sesión |
| Contraseña | La gestiona el servicio de autenticación; **no se guarda en la base de datos del juego** |
| Nombre de usuario | Único; es el que ven los demás jugadores |
| Código de jugador | "Código de amistad" único, para que otros te agreguen |
| Experiencia acumulada | El nivel se calcula a partir de ella (ver sección 11) |

Datos adicionales que se deducen del diseño **(propuesto)**:

| Dato | Para qué |
|---|---|
| Monedas de la cuenta | Tienda del juego y cosméticos |
| Diamantes de la cuenta | Cosméticos "mejores" y mejoras consumibles |
| Cosméticos desbloqueados y equipados | Personalización del personaje |
| Dados secretos (consumibles) | Se usan en próximas partidas |
| Lista de amigos | Chat e invitaciones |

### 3.2 Personaje y foto de perfil

- La **foto de perfil es el rostro del personaje**.
- El jugador puede personalizar el rostro y el cuerpo con **cosméticos** (Camisa, Pantalón, Zapatos, Cabello, Ojos, Nariz, Boca).
- Alternativa: **tomarse una foto** y usarla como cara del personaje.

### 3.3 Amigos

- Cada jugador tiene un **código de amistad** para agregar a otros.
- Los amigos pueden ser invitados a una sala y chatear (sección 12).

---

## 4. Salas

### 4.1 Tipos de sala

| Tipo | Cómo se entra |
|---|---|
| Privada | Con un código de sala que comparte el creador |
| Pública | Cualquier jugador puede unirse; también se entra a una pública aleatoria |

### 4.2 Reglas de la sala

- Mínimo **2** y máximo **6** jugadores; el **creador** define el tamaño.
- El **creador** también define el número de **rondas**, entre **5 y 25**.
- Un jugador que no crea sala puede: **ingresar un código** o **entrar a una sala pública aleatoria**.

### 4.3 Lobby y arranque

- La partida arranca cuando la sala se llena.
- Si no se llena, hay una espera de **1:30 minutos**.
  - Si al terminar el tiempo hay **2 o más** jugadores, la partida arranca.
  - Si no se llegó al mínimo, se muestra el mensaje **"¡Se ha terminado el tiempo! Invita a tus amigos a jugar"** y la sala se cierra.

---

## 5. Flujo de una partida

```
Sala llena / tiempo de espera cumplido (1:30)
        │
        ▼
Tirada inicial de dados (todos a la vez)  →  define el orden de juego
        │
        ▼
┌─────────────── RONDA (se repite de 5 a 25 veces) ───────────────┐
│ 1. Cada jugador, en orden, lanza el dado (1-6) y avanza en el   │
│    mapa; la casilla donde cae le da o le quita monedas.         │
│ 2. Cuando todos avanzaron: minijuego corto aleatorio.           │
│ 3. El ganador del minijuego recibe monedas.                     │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
Entrega de diamantes finales (4 categorías)
        │
        ▼
Resultados: ganador, experiencia, dinero y diamantes a la cuenta personal
```

### 5.1 Orden de juego

- Todos lanzan un dado **al mismo tiempo**.
- En la pantalla de cada jugador, el dado gira frente a su personaje y "cae" en un número aleatorio del 1 al 6.
- Cuando todos lanzaron, se muestra una **tabla con el orden**: el número más alto juega primero.
- **Desempate:** entre los jugadores empatados, va de **último** el que tenga el nombre de usuario más cercano a la **Z** en el abecedario.

### 5.2 Turno de un jugador

- Lanza un dado del 1 al 6 (más los dados extra que haya comprado, ver sección 8).
- El resultado define cuántas casillas **avanza**.
- Los turnos siguen el orden definido al inicio.

---

## 6. Mapa y casillas

- Tiene **varios caminos**, pero en general es **cíclico**.
- Contiene **dos tiendas**.
- Hay un **diamante** en una casilla aleatoria; los jugadores intentan llegar a él. Cuando alguien lo toma, **reaparece en otra casilla aleatoria**.

### 6.1 Tipos de casilla

| Tipo | Efecto |
|---|---|
| Positiva | Da monedas |
| Negativa | Quita monedas |
| Especial | Da un **efecto aleatorio para la siguiente ronda** |

Efectos posibles de una casilla especial:

- Dado de 3 en el siguiente turno.
- Dado de 12 en el siguiente turno.
- Regresa al inicio del mapa (no afecta demasiado porque el mapa es cíclico).
- Te quita monedas.
- Te da monedas.

Cantidad y distribución de casillas de cada tipo: **(por definir)**.

---

## 7. Economía

El juego maneja dos monedas, cada una con una versión de partida y una de cuenta:

| | Monedas de partida | Monedas de cuenta | Diamantes de partida | Diamantes de cuenta |
|---|---|---|---|---|
| Se obtienen | Casillas, minijuegos | Lo que sobra al terminar la partida | En el mapa o al final de la partida | Lo que sobra al terminar la partida |
| Se usan en | Tiendas del mapa, durante la partida | Tienda del juego y cosméticos | Para ganar la partida | Tienda con cosméticos "mejores" y mejoras consumibles |
| ¿Sirven en la siguiente partida? | No aplica | **No** | No | No |

---

## 8. Tienda de la partida

Hay **dos tiendas** en el mapa. Se compra con las **monedas de partida**. Todos los precios están **(por definir)**.

| Ítem | Efecto | Estado |
|---|---|---|
| Trampa | La colocas en una casilla; al jugador que pase por ahí le robas monedas | Definido |
| Dado extra de 3, 6 o 9 | Se suma al dado normal; giran ambos | Definido |
| Escudo | Anula la próxima trampa o casilla negativa que te toque | Propuesto |
| Repetir tirada | Vuelves a lanzar tu dado una vez | Propuesto |
| Barrera | Bloquea un camino del mapa por una ronda | Propuesto |
| Teletransporte | Te mueve a otra casilla o a una tienda; caro | Propuesto |
| Intercambio | Cambias de lugar con otro jugador; caro | Propuesto |
| Imán de monedas | Duplica lo que ganes en la próxima casilla positiva | Propuesto |
| Veneno | Un jugador concreto pierde monedas en su siguiente casilla | Propuesto |

### 8.1 Tienda del juego (fuera de partida)

- Se compra con las **monedas y diamantes de la cuenta**.
- Vende cosméticos, cosméticos "mejores" y mejoras consumibles.
- Incluye la **caja secreta de dados**: da dados extra **consumibles** que se pueden usar en próximas partidas.

---

## 9. Minijuegos

- Se juega **uno por ronda**, al terminar los movimientos de todos. El anfitrión **sortea** cuál sale.
- Es **corto**: cada teléfono muestra primero una explicación de **3 segundos** con cuenta regresiva.
- Juegan todos los que **no están ausentes** (ver sección 13). Quien estaba ausente al empezar lo ve desde fuera y no puede ganar.
- El ganador recibe **10 monedas** (provisional) y suma un minijuego ganado, que cuenta para los diamantes finales (sección 10).
- Si **nadie** hace una jugada válida, nadie gana.
- **Empates** (Para el Tiempo y Reacción): los empatados lanzan **1d6**; gana el más alto. Si vuelven a empatar, se lanza otra vez entre ellos.
- Al terminar, todos ven el resultado unos segundos: quién ganó, lo que hizo cada uno y el desempate, si lo hubo.
- Tecnología: widgets de Flutter, sin Flame (D-11). Detalles técnicos en `decisiones.md`, D-26.

### 9.1 Para el Tiempo

- Sale un **objetivo al azar entre 4 y 19 segundos** (enteros).
- El reloj se ve corriendo los **primeros 3 segundos** y luego **se esconde**.
- Cada jugador toca **¡Ya!** cuando cree que se llegó al objetivo. Solo cuenta el **primer toque**.
- Si no toca en **25 segundos**, su jugada no cuenta.
- **Gana** la menor diferencia con el objetivo, por arriba o por abajo.

### 9.2 Reacción

- Sale **"Prepárate..."** y, tras una **espera al azar entre 2 y 7 segundos**, **"¡YA!"**.
- Se toca el recuadro lo más rápido posible; se guarda cuánto tardó, en ms.
- Si toca **antes** del "¡YA!", queda **eliminado**.
- Si no toca en **10 segundos** después del "¡YA!", su jugada no cuenta.
- **Gana** el que tardó menos.

### 9.3 Globo Bomba

- El globo aguanta un número **secreto de infladas, entre 30 y 70**.
- **Por turnos**, en el orden de la partida, cada uno infla **1, 2 o 3** veces. Cada ronda empieza un jugador distinto.
- Si el globo **revienta** en tu turno, quedas **eliminado** y sale un globo nuevo con otra capacidad secreta para los que quedan.
- Si no inflas en **10 segundos**, se infla 1 vez por ti.
- **Gana** el **último** que queda.

---

## 10. Diamantes y victoria

### 10.1 Cómo se consiguen

1. **En el mapa:** llegando a la casilla del diamante.
2. **Al final de la partida**, se entrega un diamante a:

| # | Premio | Criterio |
|---|---|---|
| 1 | Mejor en minijuegos | Más minijuegos ganados |
| 2 | Peor suerte | Más casillas negativas pisadas |
| 3 | Más rico | Más monedas al final |
| 4 | Más comprador | Más compras durante la partida **(propuesto: solo cuentan compras con un costo mínimo, o ítems distintos, para que comprar barato no regale el diamante)** |

### 10.2 Ganador y empates

- Gana quien tenga **más diamantes** al final.
- Si hay **empate**, ambos ganan.
- Si una categoría de premio final tiene empate, todos los empatados reciben el diamante **(propuesto, coherente con la regla anterior)**.

---

## 11. Progresión

### 11.1 Experiencia por partida

Ganan experiencia los **3 primeros puestos**. Mientras más jugadores y más rondas, más experiencia.

```
XP = XP_base(puesto) × mult_jugadores × mult_rondas
```

| Puesto | XP base |
|---|---|
| 1º | 100 |
| 2º | 60 |
| 3º | 30 |

- **mult_jugadores** = `1 + 0.15 × (jugadores − 2)` → 1.00 con 2 jugadores hasta 1.60 con 6.
- **mult_rondas** = `0.5 + rondas / 20` → 0.75 con 5 rondas, 1.00 con 10, 1.75 con 25.
- El resultado se redondea al entero más cercano.
- En un empate, todos los empatados reciben la XP del puesto más alto.
- Un jugador desconectado recibe **0**.

Ejemplo con 10 rondas (mult_rondas = 1.00):

| Jugadores | 1º | 2º | 3º |
|---|---|---|---|
| 2 | 100 | 60 | — |
| 3 | 115 | 69 | 35 |
| 4 | 130 | 78 | 39 |
| 5 | 145 | 87 | 44 |
| 6 | 160 | 96 | 48 |

### 11.2 Curva de niveles

XP necesaria para subir del nivel `n` al `n + 1`:

```
xp_siguiente(n) = round(50 + 25 × n^1.5)
```

| Nivel | XP para subir | XP acumulada |
|---|---|---|
| 1 → 2 | 75 | 75 |
| 2 → 3 | 121 | 196 |
| 3 → 4 | 180 | 376 |
| 4 → 5 | 250 | 626 |
| 5 → 6 | 330 | 956 |
| 6 → 7 | 417 | 1 373 |
| 7 → 8 | 513 | 1 886 |
| 8 → 9 | 616 | 2 502 |
| 9 → 10 | 725 | 3 227 |

Con 4 jugadores y 10 rondas, un jugador promedio gana unos 62 XP por partida: el nivel 5 llega en unas 10 partidas y el nivel 10 en unas 50. Los valores (`25`, `1.5`, XP base) se pueden ajustar tras probar el juego.

### 11.3 Premios por nivel

Cada nivel que sube el jugador da un premio:

- Caja sorpresa de cosméticos.
- Otros premios: **(por definir)**.

---

## 12. Chat y reacciones

### 12.1 Chat con amigos

- Disponible en el **menú principal**, **no dentro de las partidas**.
- Es entre amigos (se agregan con el código de amistad).
- Solo texto en la primera versión **(propuesto)**.

### 12.2 Reacciones **(propuesto)**

- Emojis o stickers rápidos que se muestran sobre el personaje, pensados para usarse **dentro de la partida** sin necesidad de chat.
- Un conjunto fijo y pequeño de reacciones, con un límite de frecuencia para evitar spam.

---

## 13. Desconexiones y casos especiales

| Situación | Qué pasa |
|---|---|
| Un jugador se desconecta y quedan **2 o más** | La partida sigue con normalidad sin él; no recibe monedas, diamantes ni experiencia |
| Queda **un solo jugador** | No recibe premio y no se traslada a otra sala. Ve el mensaje **"Lo sentimos, no quedan jugadores :("** y el botón **[Regresar a menú]**, que lo lleva a la pantalla inicial |
| Se desconecta el **creador de la sala** | **(propuesto)** la sala pasa a otro jugador para que la partida continúe |
| Un jugador desconectado quiere volver a la partida | **(por definir)** |
| Alguien se desconecta **durante un minijuego** | El minijuego no se queda esperando: al acabarse el tiempo, su jugada no cuenta (en el Globo Bomba se infla 1 por él). Si vuelve antes, puede jugar donde iba |
| El **anfitrión** se desconecta durante un minijuego | El nuevo anfitrión sigue con el mismo minijuego: nadie pierde lo que ya jugó |

---

## 14. Pantallas principales (según mockup en Figma)

Barra de navegación con 5 secciones:

| Sección | Contenido |
|---|---|
| Inicio | Crear sala / unirse (código o aleatoria) |
| Tienda | Compra con monedas y diamantes de la cuenta |
| Vestuario | Personalización del personaje: Camisa, Pantalón, Zapatos, Cabello, Ojos, Nariz, Boca |
| Stats | Estadísticas del jugador |
| Amigos | Lista de amigos, código de amistad, invitaciones y chat |

Pantallas adicionales que se deducen del diseño **(propuesto)**: registro e inicio de sesión, lobby de sala, tablero de juego, minijuego, resultados de la partida, mensaje de "no quedan jugadores".

---

## 15. Decisiones técnicas

### 15.1 Backend: Firebase **(propuesto, por confirmar el reparto)**

| Servicio | Uso |
|---|---|
| Authentication (correo y contraseña) | Registro e inicio de sesión |
| Cloud Firestore | Perfiles, amigos, chat, catálogo de tienda e inventario |
| Realtime Database | Salas, estado de la partida y presencia (detectar desconexiones) |
| Storage | Foto del rostro del personaje |
| Reglas de seguridad | Que cada jugador solo pueda leer y modificar lo suyo |

### 15.2 Gestor de estado **(propuesto)**

- **Riverpod** como primera opción: maneja bien los flujos en tiempo real de Firebase y facilita la inyección de dependencias y las pruebas.
- Alternativas: **Provider** (más simple, si el equipo no tiene experiencia) o **Bloc** (más estructura, más código).

### 15.3 Estructura de `lib/`

```
lib/
├── controllers/
├── models/
├── screens/
├── services/
└── widgets/
```

### 15.4 Toolkit y motor de juego **(propuesto)**

- Se usa el **Flutter Casual Games Toolkit** como referencia (plantillas `basic`, `card` y `endless_runner`, y el ejemplo `multiplayer`), no se adopta completo.
- El tablero y los turnos se hacen con Flutter y Riverpod.
- **Flame** solo para minijuegos de tiempo real, decidido por minijuego.

---

## 16. Pendientes por definir

**Reglas**
- [ ] Reconexión de un jugador a la partida.
- [ ] Qué pasa si se desconecta el creador de la sala.
- [ ] Costo mínimo (o ítems distintos) para contar una compra en el premio "Más comprador".

**Contenido**
- [ ] Lista y mecánica de los minijuegos.
- [ ] Cantidad y distribución de casillas positivas, negativas y especiales.
- [ ] Monedas que da cada casilla y cada minijuego.
- [ ] Precios de los ítems de la tienda de partida y de la tienda del juego.
- [ ] Premios por subir de nivel (además de la caja sorpresa).
- [ ] Conjunto de reacciones.

**Cuenta y social**
- [ ] Moderación del chat y forma de reportar o bloquear a un jugador.
- [ ] Privacidad de las fotos de rostro, sobre todo con jugadores de 10 años en adelante.

**Técnico**
- [ ] Confirmar gestor de estado.
- [ ] Definir dónde se calcula la lógica de la partida (dados, monedas) para evitar trampas.
- [ ] Modelo de datos en Firestore y Realtime Database.
- [ ]  Decidir qué minijuegos usan Flame (después de definir la lista de minijuegos).