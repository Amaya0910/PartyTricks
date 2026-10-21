# Party Tricks — Roles y ramas del equipo

> Equipo: **Isabella Amaya** y **Brayan Vasquez**
Este documento es **propuesto**: cambien lo que no les convenga. Se actualiza durante el desarrollo (marquen las casillas al avanzar).
> 

---

## 1. Roles

| Rol | Responsable | Qué hace |
| --- | --- | --- |
| Scrum Master | Isabella | Organiza las reuniones, revisa el avance y quita bloqueos |
| Desarrollo: cuenta, diseño y social | Isabella | Pantallas, personalización, tiendas del juego, amigos y chat |
| Desarrollo: partida y backend | Brayan | Salas, motor del juego, tablero, ítems, desconexiones |
| Diseño en Figma | Isabella | Mockup de todas las pantallas, incluidas las de la partida |
| Configuración de Firebase | Brayan | Proyecto, reglas de seguridad y estructura de datos |
| Revisión de código | Ambos | Cada uno revisa los Pull Requests del otro |
| Documentación | Ambos | Cada uno documenta lo que construye |
| Minijuegos | Ambos | Se reparten la lista a medias |

La idea del reparto es dividir por **áreas de la app** (no por "pantallas" y "lógica") para que cada uno construya funcionalidades completas y se pisen menos el trabajo.

---

## 2. Ramas

### 2.1 Ramas principales

| Rama | Para qué |
| --- | --- |
| `main` | Versión estable, lista para entregar o presentar |
| `develop` | Donde se junta todo el trabajo antes de pasar a `main` |

Nadie trabaja directamente en `main` ni en `develop`.

### 2.2 Ramas de trabajo

Nombre: `feature/<área>-<descripcion-corta>`, en minúsculas y con guiones.

**Isabella**

| Rama | Qué incluye | Depende de |
| --- | --- | --- |
| `feature/auth` | Registro, inicio de sesión y perfil con código de amistad | `chore/firebase-setup` |
| `feature/navigation-shell` | Barra de navegación y pantallas base (Inicio, Tienda, Vestuario, Stats, Amigos) | — |
| `feature/wardrobe-avatar` | Vestuario, cosméticos y foto del rostro | `feature/auth` |
| `feature/game-shop` | Tienda del juego, caja secreta de dados | `feature/auth` |
| `feature/friends-chat` | Amigos por código y chat | `feature/auth` |
| `feature/stats-levels` | Pantalla de estadísticas, nivel y experiencia | `feature/auth` |

**Brayan**

| Rama | Qué incluye | Depende de |
| --- | --- | --- |
| `chore/firebase-setup` | Conectar Firebase al proyecto y estructura base de datos | — |
| `feature/rooms-lobby` | Crear sala, entrar con código o sala pública, lobby de 1:30 | `chore/firebase-setup` |
| `feature/game-engine` | Motor del juego: dados, orden de turnos, casillas, diamantes | — |
| `feature/board-turns` | Tablero y turnos en pantalla | `feature/game-engine`, `feature/rooms-lobby` |
| `feature/map-shop-items` | Tiendas del mapa, trampas y dados extra | `feature/board-turns` |
| `feature/disconnections` | Desconexiones y cambio de creador de sala | `feature/rooms-lobby` |
| `feature/results-xp` | Diamantes finales, ganador, XP y pantalla de resultados | `feature/board-turns` |

**Compartidas**

| Rama | Qué incluye | Responsable |
| --- | --- | --- |
| `feature/minigame-<nombre>` | Un minijuego por rama | Se reparten la lista a medias |
| `docs/<tema>` | Cambios en la documentación | Quien edite |
| `fix/<descripcion>` | Corrección de errores | Quien lo encuentre |

---

## 3. Reglas de trabajo

- **Una rama por tarea.** Se crea desde `develop` y se borra al terminar.
- **Commits pequeños** con prefijo: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
- **Pull Request obligatorio** para unir a `develop`, y lo revisa la otra persona antes de aceptarlo.
- **Traer `develop` seguido** a la rama de trabajo para evitar conflictos grandes.
- **Aviso en el grupo** antes de tocar archivos compartidos (modelos, rutas, tema de colores).
- `develop` pasa a `main` solo cuando funciona bien, por ejemplo antes de una entrega.

### Comandos de uso diario

```bash
# Empezar una tarea
git switch develop
git pull
git switch -c feature/auth

# Guardar el trabajo
git add .
git commit -m "feat: agregar pantalla de registro"
git push -u origin feature/auth

# Traer lo nuevo de develop a tu rama
git switch develop
git pull
git switch feature/auth
git merge develop
```

---

## 4. Orden sugerido de trabajo

| Etapa | Isabella | Brayan |
| --- | --- | --- |
| 1 | `feature/navigation-shell` | `chore/firebase-setup` |
| 2 | `feature/auth` | `feature/game-engine` y `feature/rooms-lobby` |
| 3 | `feature/wardrobe-avatar` | `feature/board-turns` |
| 4 | `feature/game-shop` y `feature/stats-levels` | `feature/map-shop-items` y `feature/results-xp` |
| 5 | `feature/friends-chat` | `feature/disconnections` |
| 6 | Minijuegos (mitad de la lista) | Minijuegos (mitad de la lista) |

Así los dos pueden avanzar a la vez desde el inicio: la navegación y el motor del juego no necesitan esperar a Firebase.

---

## 5. Definición de "terminado"

Una tarea está terminada cuando:

- [ ]  Funciona en el emulador o en un celular.
- [ ]  No rompe lo que ya existía.
- [ ]  Está unida a `develop` con Pull Request revisado.
- [ ]  Si cambia algo del diseño o de la arquitectura, se actualizó el documento correspondiente.

---

## 6. Seguimiento

| Rama | Responsable | Estado |
| --- | --- | --- |
| `chore/firebase-setup` | Brayan | 🟢 Listo |
| `feature/navigation-shell` | Isabella | 🟢 Listo |
| `feature/auth` | Isabella | 🟢 Listo |
| `feature/rooms-lobby` | Brayan | 🟢 Listo |
| `feature/game-engine` | Brayan | 🟢 Listo |
| `feature/wardrobe-avatar` | Isabella | 🟡 Pendiente |
| `feature/board-turns` | Brayan | 🟢 Listo |
| `feature/map-shop-items` | Brayan | 🟡 Pendiente |
| `feature/results-xp` | Brayan | 🟡 Pendiente |
| `feature/game-shop` | Isabella | 🟡 Pendiente |
| `feature/stats-levels` | Isabella | 🟡 Pendiente |
| `feature/friends-chat` | Isabella | 🟡 Pendiente |
| `feature/disconnections` | Brayan | 🟡 Pendiente |
| Minijuegos | Ambos | 🟡 Pendiente |