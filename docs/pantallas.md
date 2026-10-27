# Party Tricks — Pantallas y navegación

> Proyecto de aula · Programación Móvil
> Basado en el mockup de Figma y en el código actual de `lib/screens/`.
> Complementa a `diseno_juego.md` (sección 14) y `arquitectura.md`.
> Última actualización: 2026-10-26

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
| Stats | `stats_screen.dart` | Base | Estadísticas de partidas, minijuegos y tiempo |
| Amigos | `friends_screen.dart` | Base | Lista de amigos, invitar a jugar y chat |

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
- El botón **Salir** saca al jugador de la sala.
- Cuando la sala arranca, todos pasan al tablero.

### 3.2 Tablero de juego

Archivos: `board_screen.dart` y `board_view.dart`.

- Arriba, el **tablero** de 42 casillas en una cuadrícula de 9×8 (provisional hasta tener el dibujo): salida, positivas, negativas, especiales y tiendas, con el diamante y las fichas de colores de cada jugador.
- Abajo, un panel con la **ronda actual**, la lista de jugadores (monedas y diamantes) y el botón de lo que toca hacer:
  - **Lanzar dado** (cuando es tu turno).
  - **Seguir** o **Atajo** (cuando llegas a una bifurcación).
  - **Simular minijuego** (solo el creador; provisional hasta tener minijuegos).
- Al terminar la última ronda se muestra el ganador en el panel. La pantalla de resultados llega en `feature/results-xp`.
- Todavía no se puede salir a mitad de partida (llega con `feature/disconnections`).

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

| Grupo | Datos |
|---|---|
| Partidas | Ganadas, perdidas, porcentaje de ganadas, máximo de diamantes y de monedas en una partida |
| Minijuegos | Ganados, perdidos, porcentaje de ganados, máximo de ganados en una partida y mejor puntaje |
| Tiempo | En la app, jugando y en minijuegos |
| Rachas | Racha actual y racha máxima (en días) |

---

## 7. Amigos

- **Lista de amigos**, cada uno con un botón para invitarlo a jugar (`Jugamos?`).
- Botón **+** para agregar a alguien con su código de amistad.
- **Chat** con un amigo (campo "Presiona para escribir"). El chat solo está en el menú principal, no dentro de las partidas.

---

## 8. Cuenta y configuración

Pantallas que aparecen en el mockup (todavía no están construidas):

| Pantalla | Contenido |
|---|---|
| Perfil / cuenta | Código del jugador (copiar y recargar), nombre de usuario, correo y botón de cambiar contraseña |
| Preferencias | Notificaciones, sonido, efectos de sonido e idioma (Español) |
| Más opciones | Acerca de, Términos y condiciones, Política de privacidad |
| Cambiar contraseña | Contraseña actual, nueva y confirmación (mínimo 8 caracteres, con mayúscula, minúscula, número y símbolo; ver `decisiones.md`, D-16) |

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
- [ ] Perfil, preferencias y cambio de contraseña (ver sección 8).