# Party Tricks

Juego 2D multijugador por turnos con minijuegos, para jugar en el celular con amigos. Los jugadores recorren un mapa lanzando dados, ganan o pierden monedas según la casilla, compran ítems en las tiendas del mapa, compiten en minijuegos cortos y se disputan diamantes. Gana quien tenga más diamantes al final.

> Proyecto de aula · Programación Móvil · Equipo: Isabella Amaya y Brayan Vasquez

## Qué incluye

- **Cuenta:** registro e inicio de sesión con correo y contraseña o con Google, verificación del correo, Ajustes (nombre, código de amistad, correo, contraseña, preferencias) y bloqueo de jugadores.
- **Partida en línea:** salas privadas (con código) y públicas, lobby de 1:30, tablero con dados, caminos que se bifurcan, casillas especiales con 14 efectos, tiendas del mapa con mochila de ítems y turno de 40 s.
- **Minijuegos:** Para el Tiempo, Reacción y Globo Bomba.
- **Resultados:** ganador, diamantes finales, experiencia, monedas y estadísticas de cada jugador.
- **Desconexiones:** presencia en tiempo real, cambio automático de anfitrión, salto de turnos y reconexión a una partida en curso.
- **Personalización:** personaje con piel, ojos, boca, cabello, camisa, pantalón y accesorios, vistas de frente, de lado y de espalda, y foto de la cara opcional.
- **Tienda y cofres:** cosméticos por rareza, cofres con diamantes y dados extra.
- **Social:** amigos por código, chat, invitaciones a la party, reportes y notificaciones de mensajes e invitaciones.
- **Administración:** galería, vista previa de animaciones y del mapa, estadísticas generales y práctica de minijuegos (solo cuentas de administrador).

El detalle de cada punto, con su estado, está en [`docs/requerimientos.md`](docs/requerimientos.md).

## Tecnologías

- **App:** Flutter (Dart `^3.12`) para Android; el código también compila para iOS y web.
- **Backend:** Firebase: Authentication, Cloud Firestore, Realtime Database, Cloud Messaging y Cloud Functions (`functions/`, Node 20).
- **Gestor de estado:** Riverpod.
- **Juego:** el tablero y los turnos son Flutter puro; Flame solo si un minijuego de tiempo real lo necesita (`docs/decisiones.md`, D-11). El celular del anfitrión hace de servidor de la partida (D-15).

## Cómo ejecutarlo

Requisitos: Flutter con Dart 3.12 o más y acceso al proyecto de Firebase `party-tricks` (`lib/firebase_options.dart` y `android/app/google-services.json` ya vienen en el repositorio).

```bash
flutter pub get
flutter run
```

Revisar el código y correr las pruebas:

```bash
flutter analyze
flutter test
```

### Pruebas de las reglas de Firebase

Prueban `firestore.rules` y `database.rules.json` con el emulador local, sin tocar el proyecto real. Necesitan Node.js 20 o más y Java 21 o más:

```bash
cd rules_test
npm ci
npm test
```

Más detalle en [`rules_test/README.md`](rules_test/README.md).

### Cloud Functions (notificaciones)

```bash
cd functions
npm ci
npm test
```

Para desplegarlas hace falta el plan Blaze (`firebase deploy --only functions`).

### Publicar las reglas de Firebase

```bash
firebase deploy --only firestore:rules
firebase deploy --only database
```

### Versión release de Android

Se firma con la llave del equipo, que **no** está en Git. Copia `android/key.properties.example` como `android/key.properties`, llénalo y compila con el código ofuscado (Gradle falla a propósito si falta la llave o las banderas):

```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

Guarda la carpeta de símbolos de cada versión para leer los errores. Las huellas SHA de la llave deben estar registradas en Firebase para que funcione el inicio con Google.

## Estructura del repositorio

```
lib/
├── controllers/   lógica de cada pantalla (Riverpod)
├── models/        datos y estados
├── navigation/    navegación raíz
├── screens/       pantallas (y admin/ para administración)
├── services/      Firebase y reglas del juego (game_engine/ no depende de Firebase)
├── theme/         colores y tema de la app
└── widgets/       componentes reutilizables y minijuegos
assets/            imágenes, mapa (Tiled), tipografía Inter e ícono
functions/         Cloud Functions de las notificaciones
rules_test/        pruebas de las reglas con el emulador
test/              pruebas unitarias, de integración y de widgets
docs/              documentación del proyecto
firestore.rules, database.rules.json   reglas de seguridad de Firebase
```

## Seguridad

La app pasó por una auditoría con el OWASP Mobile Top 10 (2024). Están corregidos los hallazgos H-01, H-03, H-04, H-05, H-06, H-08, H-09, H-10 y H-13; siguen abiertos H-02, H-07, H-11 y H-12. El estado y los motivos están en [`docs/requerimientos.md`](docs/requerimientos.md) (sección 3.4) y en [`docs/decisiones.md`](docs/decisiones.md) (D-48).

## Documentación

Todo el detalle está en la carpeta [`docs/`](docs/README.md):

- [Requerimientos](docs/requerimientos.md)
- [Diseño del juego](docs/diseno_juego.md)
- [Arquitectura](docs/arquitectura.md)
- [Pantallas y navegación](docs/pantallas.md)
- [Modelos de datos](docs/modelo_datos.md)
- [Tiendas del mapa e ítems](docs/map_shop_items.md)
- [Resultados y XP](docs/results_system.md)
- [Desconexiones](docs/disconnections.md)
- [Arte e imágenes](docs/arte_imagenes.md)
- [Decisiones técnicas](docs/decisiones.md)
- [Progreso del desarrollo](docs/progreso_desarrollo.md)
- [Roles y ramas](docs/roles_y_ramas.md)

La documentación se actualiza siempre en la rama `docs/documentacion-completa` (ver `docs/roles_y_ramas.md`).
