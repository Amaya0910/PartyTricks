# Party Tricks — Roles y ramas del equipo

> Equipo: **Isabella Amaya** y **Brayan Vasquez**
> Este documento es **propuesto**: cambien lo que no les convenga. Se actualiza durante el desarrollo (marquen las casillas al avanzar).
> Última actualización: 2026-10-27

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

### 2.2 Rama permanente de documentación

| Rama | Para qué |
| --- | --- |
| `docs/documentacion-completa` | **Única rama para la documentación.** No se borra: se reutiliza cada vez que se actualiza la carpeta `docs/` o el `README.md` |

Cómo se usa (ver los comandos en la sección 3):

1. Antes de editar, se trae `develop` a esta rama para que no quede atrasada.
2. Se editan los documentos, con commits `docs:`.
3. Se abre un Pull Request hacia `develop`, que revisa la otra persona.
4. Al unirse, la rama se queda; la próxima actualización empieza otra vez en el paso 1.

### 2.3 Ramas de trabajo

Nombre: `feature/<área>-<descripcion-corta>`, en minúsculas y con guiones.

Se prefieren **pocas ramas, una por área grande**: no se crea una rama por cada pantalla, diálogo o widget.

**Isabella**

| Rama | Qué incluye | Depende de |
| --- | --- | --- |
| `feature/ui` | Toda la interfaz visual: barra de navegación y pantallas base (Inicio, Tienda, Vestuario, Stats, Amigos), diálogos (incluido "Alista tu party"), widgets reutilizables, colores en `AppColors` y ajustes al mockup | — |
| `feature/auth` | Registro, inicio de sesión y perfil con código de amistad | `chore/firebase-setup` |
| `feature/player-profile` | Vestuario, cosméticos, foto del rostro, estadísticas, nivel y experiencia | `feature/auth` |
| `feature/game-shop` | Tienda del juego: cofres, cosméticos y dados extra | `feature/auth` |
| `feature/friends-chat` | Amigos por código y chat | `feature/auth` |

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
| `docs/documentacion-completa` | Toda la documentación (rama permanente, ver 2.2) | Quien edite |
| `fix/<descripcion>` | Corrección de errores | Quien lo encuentre |

---

## 3. Reglas de trabajo

- **Pocas ramas.** Se trabaja con la menor cantidad posible: `main`, `develop`, la rama permanente de documentación y solo las ramas de trabajo que estén abiertas en ese momento.
- **Una rama por área o tarea grande.** Se crea desde `develop` y se borra al terminar (la rama de documentación es la excepción). Si `feature/ui` ya se unió y hay más cambios visuales, se vuelve a crear con el mismo nombre desde `develop`.
- **Limpiar al unir.** Cuando un Pull Request se une, se borra su rama en GitHub y en local (ver comandos abajo).
- **Una rama no se crea desde otra rama de trabajo** (por ejemplo, `feature/game-shop` desde `feature/player-profile`): el segundo Pull Request arrastra los commits del primero. Si hay dependencia, se une primero la rama de la que depende.
- **Agrupar en vez de dividir.** Los cambios pequeños del mismo tipo (por ejemplo, varios ajustes visuales) van juntos en una sola rama, con commits separados.
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

### Actualizar la documentación (rama permanente)

```bash
git switch develop
git pull
git switch docs/documentacion-completa
git merge develop

# ... editar los archivos de docs/ ...

git add docs/ README.md
git commit -m "docs: actualizar documentación"
git push
# Abrir el Pull Request hacia develop en GitHub
```

### Borrar ramas ya unidas

```bash
# En local
git branch -d feature/game-shop

# En GitHub (también se puede con el ícono de la papelera)
git push origin --delete feature/game-shop

# Quitar de la lista las ramas que ya no existen en GitHub
git fetch --prune
```

---

## 4. Orden sugerido de trabajo

| Etapa | Isabella | Brayan |
| --- | --- | --- |
| 1 | `feature/ui` | `chore/firebase-setup` |
| 2 | `feature/auth` | `feature/game-engine` y `feature/rooms-lobby` |
| 3 | `feature/player-profile` | `feature/board-turns` |
| 4 | `feature/game-shop` | `feature/map-shop-items` y `feature/results-xp` |
| 5 | `feature/friends-chat` | `feature/disconnections` |
| 6 | Minijuegos (mitad de la lista) | Minijuegos (mitad de la lista) |

Así los dos pueden avanzar a la vez desde el inicio: la interfaz y el motor del juego no necesitan esperar a Firebase.

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
| `feature/ui` | Isabella | 🟡 En proceso (se reabre con cada lote de cambios visuales) |
| `feature/auth` | Isabella | 🟢 Listo |
| `feature/rooms-lobby` | Brayan | 🟢 Listo |
| `feature/game-engine` | Brayan | 🟢 Listo |
| `feature/player-profile` | Isabella | 🟡 En proceso (vestuario y estadísticas listos; faltan cosméticos desbloqueados, foto, nivel y experiencia) |
| `feature/board-turns` | Brayan | 🟢 Listo |
| `feature/map-shop-items` | Brayan | 🔴 Pendiente |
| `feature/results-xp` | Brayan | 🔴 Pendiente |
| `feature/game-shop` | Isabella | 🟡 En proceso (cofres listos; faltan cosméticos e ítems en la tienda) |
| `feature/friends-chat` | Isabella | 🔴 Pendiente |
| `feature/disconnections` | Brayan | 🔴 Pendiente |
| `docs/documentacion-completa` | Ambos | 🟢 Rama permanente (se reutiliza en cada actualización) |
| Minijuegos | Ambos | 🔴 Pendiente |