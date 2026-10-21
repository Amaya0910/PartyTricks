# Party Tricks — Pantallas y navegación

> Proyecto de aula · Programación Móvil
> Basado en el mockup de Figma y en el código actual de `lib/screens/`.
> Complementa a `diseno_juego.md` (sección 14) y `arquitectura.md`.

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
| Tienda | `shop_screen.dart` | Base | Tienda de Tricks: cofres (50, 100, 150) y cosméticos con precio |
| Vestuario | `wardrobe_screen.dart` | Base | Foto del rostro y categorías: Camisa, Pantalón, Zapatos, Cabello, Nariz, Ojos, Boca |
| Stats | `stats_screen.dart` | Base | Estadísticas de partidas, minijuegos y tiempo |
| Amigos | `friends_screen.dart` | Base | Lista de amigos, invitar a jugar y chat |

**Estado:** _Base_ = pantalla provisional con un texto; _En desarrollo_ = ya tiene interfaz.

---

## 3. Inicio

- **Cabecera del jugador:** foto de perfil, nombre de usuario, monedas y diamantes. Los datos salen del perfil del jugador con la sesión iniciada.
- **Personaje:** el rostro armado con los cosméticos equipados (por ahora, un ícono provisional).
- **Botón Jugar:** abre un menú emergente con tres opciones.

### Menú de Jugar

| Opción | Qué hace | Estado |
|---|---|---|
| Alista tu party | Crea una sala; el creador define jugadores y rondas. Muestra el código de la sala y la lista de jugadores | Por conectar (`feature/rooms-lobby`) |
| Unirse a Party | Pide un código de sala (6 dígitos en el mockup) | Por conectar |
| Juego Random | Entra a una sala pública aleatoria | Por conectar |

---

## 4. Tienda

- Encabezado **Tienda de Tricks** con los **cofres** (precios 50, 100 y 150): Cofre Básico, Cofre Party y **Dados secretos**, el cofre donde se compran dados extra.
- Cada cofre muestra sus **probabilidades** de premio: dado extra, 100 monedas, cosmético aleatorio o nada.
- Lista de cosméticos con nombre, descripción y precio (por ejemplo, camisas de distintos colores).
- Botón **Comprar** para cada ítem.

---

## 5. Vestuario

- Foto del rostro del personaje, con la opción **Tomar** para usar una foto propia (**opcional**).
- Pestañas por categoría: Camisa, Pantalón, Zapatos, Cabello, Nariz, Ojos y Boca.
- Cada categoría muestra los cosméticos desbloqueados para equipar.

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

Pantallas que aparecen en el mockup:

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
- [ ] Lobby de sala (espera de 1:30 minutos).
- [ ] Tablero de juego y turnos.
- [ ] Minijuego (puede usar Flame si es de tiempo real; ver `decisiones.md`, D-11).
- [ ] Resultados de la partida.
- [ ] Mensaje "Lo sentimos, no quedan jugadores :(" con el botón **[Regresar a menú]**.