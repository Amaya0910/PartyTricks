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