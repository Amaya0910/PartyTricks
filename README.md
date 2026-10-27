# Party Tricks

Juego 2D multijugador por turnos con minijuegos, para jugar en el celular con amigos. Los jugadores recorren un mapa lanzando dados, ganan o pierden monedas según la casilla, compiten en minijuegos cortos y se disputan diamantes. Gana quien tenga más diamantes al final.

> Proyecto de aula · Programación Móvil · Equipo: Isabella Amaya y Brayan Vasquez

## Tecnologías

- **App:** Flutter
- **Backend:** Firebase (Authentication, Cloud Firestore, Realtime Database y Storage)
- **Gestor de estado:** Riverpod
- **Juego:** [Flutter Casual Games Toolkit](https://docs.flutter.dev/resources/games-toolkit) como referencia; Flame solo en los minijuegos de tiempo real que lo necesiten (ver `docs/decisiones.md`, D-11)

## Cómo ejecutarlo

```bash
flutter pub get
flutter run
```

Para revisar el código y correr las pruebas:

```bash
flutter analyze
flutter test
```

## Estructura de `lib/`

```
lib/
├── controllers/   lógica de cada pantalla (Riverpod)
├── models/        datos y estados
├── screens/       pantallas
├── services/      comunicación con Firebase y reglas del juego
├── theme/         colores y tema de la app
└── widgets/       componentes reutilizables
```

## Documentación

Todo el detalle está en la carpeta [`docs/`](docs/README.md):

- [Diseño del juego](docs/diseno_juego.md)
- [Arquitectura](docs/arquitectura.md)
- [Pantallas y navegación](docs/pantallas.md)
- [Modelos de datos](docs/modelo_datos.md)
- [Decisiones técnicas](docs/decisiones.md)
- [Roles y ramas](docs/roles_y_ramas.md)

La documentación se actualiza siempre en la rama `docs/documentacion-completa` (ver `docs/roles_y_ramas.md`).