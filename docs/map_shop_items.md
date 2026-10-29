# Party Tricks — Tiendas del mapa e ítems

> Rama: `feature/map-shop-items`. Cómo funcionan las dos tiendas del mapa, la mochila de cada jugador y los ítems que se compran en ellas. Las reglas generales están en `diseno_juego.md` (sección 8).

---

## 1. Cuándo se abre la tienda

- La tienda se abre **solo si el jugador CAE** en una casilla tienda (la 17 y la 36 en el primer mapa). Pasar por encima no hace nada.
- También cuenta si llega a la tienda después de elegir camino en una bifurcación: lo que importa es la casilla donde termina el movimiento.
- Al caer, la partida pasa a la fase `shopping` y el turno **no** pasa al siguiente. El jugador compra lo que quiera (si le alcanza) y toca **Terminar** para pasar el turno.
- Mientras está en la tienda nadie más puede lanzar el dado ni comprar.

## 2. Ítems

Los precios y cantidades son **provisionales** (`ShopItem` y `ItemRules` en `lib/services/game_engine/shop_items.dart`).

| Ítem | Precio | Tipo | Efecto |
|---|---|---|---|
| Dado extra de 3 | 4 | Activo | Al lanzar, se suma un dado de 3 al normal |
| Dado extra de 6 | 6 | Activo | Al lanzar, se suma un dado de 6 al normal |
| Dado extra de 9 | 9 | Activo | Al lanzar, se suma un dado de 9 al normal |
| Impulso (Movement Boost) | 4 | Activo | Avanza 3 casillas más en la tirada |
| Trampa | 5 | Activo | Se deja en la casilla donde está el jugador. Al rival que pase por ahí (o caiga) le roba 5 monedas, o las que tenga |
| Escudo | 5 | Pasivo | Anula la próxima trampa o casilla negativa |
| Diamante doble (Diamond Boost) | 12 | Pasivo | La próxima vez que toma el diamante del mapa gana uno más |

Reglas:

- Caben como máximo **3 de cada ítem** en la mochila.
- Los **activos** se usan desde la **Mochila**, en tu turno y **antes** de lanzar el dado. Se gastan al usarlos.
- Solo un dado extra y un impulso por tirada (se pueden combinar entre ellos).
- La trampa **no** se puede poner en la salida, en una tienda ni donde ya hay otra trampa. La propia trampa no le hace nada a quien la puso.
- Los **pasivos** no se activan: se gastan solos cuando hacen falta. Si el jugador cae en una trampa y además en una casilla negativa, gasta un escudo por cada una.
- Un escudo que anula una casilla negativa no borra el conteo de "casillas negativas" (premio a la peor suerte).
- Las estadísticas de dados (`diceRolled`, `diceTotal`, `maxRolls`) solo cuentan el dado normal.

## 3. Arquitectura

Se reutilizó el motor que ya existía (`lib/services/game_engine/`), sin crear capas nuevas:

| Pieza | Qué hace |
|---|---|
| `shop_items.dart` | `ShopItem` (catálogo con nombre, precio y tipo) e `ItemRules` (cantidades) |
| `game_state.dart` | Fase `shopping`; por jugador `inventory`, `activeItems` e `itemsUsed`; por partida `traps`, `lastExtraRoll` y `lastBoost` |
| `game_action.dart` | Acciones nuevas `BuyItem`, `LeaveShop` y `UseItem` |
| `game_engine.dart` | Aplica las reglas. `whyCannotBuy` y `whyCannotUse` dicen por qué algo no se puede, y la pantalla los usa para desactivar botones con el motivo |
| `game_codec.dart` | Guarda y lee todo lo nuevo en Realtime Database |
| `game_service.dart` | `hostApply`: el paso del anfitrión (leer estado, aplicar acción, devolver estado). `FirebaseGameService` lo usa y las pruebas también |
| `map_items_dialog.dart` | Diálogo de **Tienda** y de **Mochila**, con la partida en vivo |
| `board_screen.dart` | Botones **Lanzar dado / Mochila** y **Tienda / Terminar**; muestra el dado extra y el impulso en "Último dado" |
| `board_map_view.dart` y `board_view.dart` | Dibujan las trampas (en el mapa, con el color de quien la puso) |

Flujo en multijugador (igual que el resto de la partida, ver D-15):

1. El jugador manda la acción a `rooms/{id}/actions` (`buy`, `useItem` o `leaveShop`).
2. El anfitrión la aplica con el motor. Si no vale (no es su turno, no le alcanza, ya tiene 3...), la descarta sin cambiar nada.
3. El anfitrión guarda el estado nuevo en `rooms/{id}/game` y todos lo ven.

## 4. Persistencia

Todo vive en `rooms/{id}/game`, que solo escribe el anfitrión:

| Campo | Dónde | Formato |
|---|---|---|
| `inventory` | `players/{uid}` | `{ "shield": 2, "trap": 1 }`; los que están en 0 no se guardan |
| `activeItems` | `players/{uid}` | `["extraDie6", "movementBoost"]`, se vacía al lanzar |
| `itemsUsed` | `players/{uid}` | Ítems gastados (consumos) |
| `purchases` | `players/{uid}` | Compras (ya existía; ahora se llena). Cuenta para el premio "Más comprador" y para `shopPurchases` en las estadísticas |
| `traps` | raíz de `game` | `{ "t17": "uidDeQuienLaPuso" }`. Las claves llevan una `t` para que la base de datos no convierta el mapa en lista |
| `lastExtraRoll`, `lastBoost` | raíz de `game` | Lo que sumó el dado extra y el impulso en la última tirada |

Compatibilidad:

- Los campos que faltan se leen vacíos o en 0: las partidas guardadas antes de esta rama siguen funcionando.
- Un ítem que la versión de la app no conoce se ignora al leer el estado, y una acción con un ítem desconocido se descarta (no rompe la cola del anfitrión).

Reglas de Realtime Database (`database.rules.json`): `buy` y `useItem` exigen `playerId === auth.uid` y un `item` de la lista; `leaveShop` exige `playerId === auth.uid`. Se probaron con el emulador (15 casos: válidos, a nombre de otro, ítem inventado o faltante, campos extra, no miembro, y que un jugador no pueda editar su mochila en `game`).

## 5. Pruebas

| Archivo | Tipo | Qué prueba |
|---|---|---|
| `test/services/game_engine/map_shop_test.dart` | Unitarias | Entrar a la tienda solo al caer, comprar, salir, cada ítem, trampas, escudo, límites y errores |
| `test/services/game_engine/game_codec_test.dart` | Unitarias | Guardar y leer mochila, trampas y acciones; partidas viejas; tipos raros de la base de datos |
| `test/services/game/map_shop_flow_test.dart` | Integración | Partida de 3 rondas en el mapa real pasando cada acción por el codec y `hostApply`, como el anfitrión con Firebase |
| `test/widgets/map_items_dialog_test.dart` | Widgets | Tienda y mochila: precios, botones desactivados con motivo, compras, uso y scroll en teléfonos pequeños |
| `test/widgets/board_view_test.dart` | Widgets | Las trampas se dibujan en el tablero |

## 6. Pendiente

- Precios y cantidades definitivos (están en `shop_items.dart`).
- Avisar en pantalla cuando alguien cae en una trampa o se gasta un escudo (hoy solo se ve en las monedas y en la trampa que desaparece).
- Si el jugador que está en la tienda se desconecta, la partida queda esperando: se resuelve en `feature/disconnections`, igual que con las bifurcaciones.
- El "dado extra" que dan los cofres de la tienda del juego (`extraDice` en el perfil) todavía no se puede usar dentro de la partida.
