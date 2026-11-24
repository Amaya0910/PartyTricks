# Activación remota de mapas

Un mapa aparece en el selector y en "Crear sala" **solo si se cumplen las dos cosas**:

| Condición | Dónde | Qué significa |
|---|---|---|
| `selectable == true` | `MapDefinition` en `map_catalog.dart` (compilado) | El mapa está terminado en esta versión: arte, `.tmj`, tema, pruebas. |
| `enabled == true` | `config/maps/{mapId}` en Realtime Database | El equipo decidió mostrarlo ahora. Se cambia sin publicar la app. |

`mapa_01` es la excepción: siempre está encendido. Es el respaldo cuando Firebase no responde, y la 1.0.0 lo juega sin preguntar.

## Estructura

```json
{
  "config": {
    "maps": {
      "mapa_dulces": { "enabled": true }
    }
  }
}
```

- Un mapa sin entrada, o con `enabled` distinto de `true` (booleano), está **apagado**.
- Una entrada de un mapa que la versión instalada no conoce se ignora. Por eso se puede encender un mapa antes de que salga la versión que lo trae: aparece en cuanto el jugador actualiza.
- Se pueden agregar otros campos a cada entrada (por ejemplo `"note"`): la app los ignora.

## Cómo lo lee la app

- `FirebaseMapConfigService` deja **un listener** en `config/maps` mientras hay sesión (`remoteMapConfigProvider`). Los cambios llegan en segundos, sin reiniciar la app.
- El "caché" es el del SDK: el último valor queda en memoria mientras el listener vive. No se guarda en disco a propósito: sin conexión al abrir la app se muestran solo los mapas de respaldo.
- `withFallback`: si Firebase falla (sin permiso, sin sesión) o no responde en 5 s, la configuración vale `RemoteMapConfig.unavailable` (solo `mapa_01`). Si responde después, se usa.
- Si apagan el mapa con "Crear sala" abierto, el diálogo vuelve a `mapa_01`.

## Qué protegen las reglas

Al **crear** una sala, `rooms/{id}/meta/mapId` tiene que ser `mapa_01` o un mapa con `config/maps/{mapId}/enabled === true`. Las salas que ya existen no se revisan otra vez (`data.val() === newData.val()`): apagar un mapa no corta las partidas en curso. Si las reglas rechazan la sala, la app muestra "Ese mapa ya no está disponible" y suelta el código reservado.

`config/maps` se lee con sesión y **nadie** lo puede escribir desde la app (`.write: false`); solo la consola o el Admin SDK.

## Lanzar un mapa

1. Publicar la versión con el mapa en el catálogo y `selectable: true`, con las reglas ya desplegadas. Como `config/maps/{id}` no existe, nadie lo ve todavía.
2. El día del lanzamiento, en la consola de Firebase → Realtime Database, crear `config/maps/{id}/enabled = true`.
3. Revisar que aparezca en un teléfono (sale en segundos).

## Apagarlo (rollback)

Poner `config/maps/{id}/enabled = false` (o borrar la entrada). En segundos desaparece del selector de todos los que tienen la app abierta y las reglas rechazan salas nuevas con ese mapa. Las partidas en curso terminan normalmente.

Para un problema de código (no de "mostrar o no") sigue haciendo falta una versión nueva; mientras sale, el mapa queda apagado desde Firebase.
