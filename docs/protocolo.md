# Protocolo de juego y compatibilidad entre versiones

Varias versiones de la app pueden estar instaladas al mismo tiempo, y todas juegan en la misma base de datos. Si una versión vieja entra a una partida que usa algo que no conoce (un mapa, un minijuego, una acción), la juega mal: ve otro tablero, aplica otras reglas o corrompe la partida. El **protocolo** evita eso.

## Qué es

Un número entero que dice qué entiende una versión de la app. Todo está en un solo archivo: `lib/models/app_protocol.dart`.

| Nombre | Qué es |
|---|---|
| `ProtocolLevel` | Los niveles con nombre (`base = 1`, `roomProtocol = 2`, ...). **Los únicos números del protocolo en todo el proyecto.** |
| `AppProtocol.current` | El protocolo de esta versión: el nivel más alto de `ProtocolLevel`. |
| `AppProtocol.legacy` | El de la 1.0.0 (`base`), que no escribe ningún campo de protocolo. |
| `ProtocolFeature` | Algo de la partida que necesita un protocolo mínimo (`minProtocol`). Hoy lo implementa `MapDefinition`. |
| `rooms/{id}/meta/requiredProtocol` | El mínimo para entrar a la sala: el mayor `minProtocol` de lo que usa. Lo calcula quien crea la sala (`requiredProtocolFor` en `room_protocol.dart`) y no cambia. |
| `rooms/{id}/players/{uid}/protocol` | El protocolo de la app con la que entró cada jugador. |

Lo que no tiene estos campos (salas y jugadores de la 1.0.0) cuenta como `legacy`.

## Cómo protege

1. **Reglas de Firebase** (funcionan también contra versiones ya instaladas, porque corren en el servidor):
   - En una sala con `requiredProtocol` mayor a 1, solo puede entrar un jugador que publique un `protocol` igual o mayor. La 1.0.0 no publica nada, así que no entra; sin estar en `players` tampoco puede mandar acciones ni tomar el lugar del anfitrión.
   - `requiredProtocol` no se puede cambiar una vez creada la sala.
   - `publicLobby` (la lista que lee la 1.0.0) solo acepta salas de protocolo 1. Las demás van en `publicLobbyByProtocol/{n}`.
2. **La app** (mensajes claros desde esta versión en adelante):
   - `FirebaseRoomService._join` no intenta entrar a una sala que pide más que `AppProtocol.current` y explica que hay que actualizar.
   - `BoardScreen` muestra "necesita una versión más nueva" si la sala pide más, o si el mapa de la partida no está en el catálogo (defensa extra por si el catálogo y el protocolo no coinciden).
   - El anfitrión descarta las acciones de partidas cuyo mapa no conoce.

## Cuándo se sube

Se sube cuando se agrega algo que **una versión anterior jugaría mal** si entrara a la partida.

| Incompatible: subir el protocolo | Compatible: no hace falta |
|---|---|
| Un mapa nuevo (las viejas usarían el tablero de `mapa_01`) | Arreglar un error que no cambia el estado guardado |
| Un minijuego nuevo (las viejas no lo pueden mostrar ni jugar) | Cambiar textos, colores, animaciones o sonidos |
| Una acción nueva (`GameAction`) que la versión vieja no sabe aplicar como anfitriona | Mejorar el rendimiento |
| Un ítem nuevo, o cambiar lo que hace uno que ya existe | Un campo nuevo que es **solo visual** y que las viejas pueden ignorar |
| Cambiar una regla del motor (monedas, dados, casillas) que el anfitrión aplica | Pantallas que no tocan la partida (perfil, tienda de cofres, amigos) |
| Un campo nuevo en la partida sin el cual el estado queda mal | Estadísticas que no cambian la partida |

Si hay duda, se sube: una versión vieja que no puede entrar es mucho mejor que una partida rota.

## Quién lo sube y cómo

Lo sube **quien hace el cambio incompatible**, en el mismo PR, y quien revisa el PR lo confirma:

1. En `app_protocol.dart`, agregar un nivel con nombre a `ProtocolLevel` (por ejemplo `static const candyMap = 3;`) y apuntar `AppProtocol.current` a él.
2. Darle ese nivel a lo nuevo: `minProtocol: ProtocolLevel.candyMap` en su `MapDefinition`, o en el `ProtocolFeature` que corresponda.
3. Si lo nuevo es de otro tipo (minijuego, ítem, acción), hacer que implemente `ProtocolFeature` y agregarlo a `featuresOf` en `room_protocol.dart`, para que cuente al calcular `requiredProtocol`.
4. Nunca reutilizar ni bajar un número. Cada nivel es para siempre.
5. Anotar el nivel nuevo en `decisiones.md`.

> **Ojo con los minijuegos y los ítems:** una partida puede sortear cualquiera de los que estén activos. Si un minijuego nuevo pide el nivel 3 y todas las partidas lo pueden sortear, todas las salas piden 3 y las versiones viejas ya no pueden jugar ninguna. Si se quiere que las viejas sigan jugando, la sala tiene que decidir al crearse qué minijuegos usa (y guardarlo); `featuresOf` cuenta solo esos.

## Cómo publicar una versión que sube el protocolo

1. Desplegar las reglas de Firebase **antes** de publicar la app.
2. Publicar primero una versión que **entienda** el nivel nuevo pero **todavía no lo use** por defecto (por ejemplo, con el mapa nuevo en el catálogo pero sin poder elegirlo).
3. Esperar a que la mayoría de los jugadores actualice.
4. Recién ahí activar lo nuevo para que las salas lo usen.

Las versiones viejas siguen jugando las salas que no lo usan. Solo dejan de poder entrar a las que sí.
