# Party Tricks — Documentación

> Proyecto de aula · Programación Móvil · Flutter + Firebase
> Equipo: **Isabella Amaya** y **Brayan Vasquez**

Este es el índice de la documentación. Cada documento tiene un propósito; si algo cambia en el proyecto, se actualiza el documento que corresponde.

| Documento | Qué contiene |
|---|---|
| [`requerimientos.md`](requerimientos.md) | Requerimientos funcionales y no funcionales, con prioridad y estado |
| [`diseno_juego.md`](diseno_juego.md) | Concepto, reglas, mecánicas y flujo de una partida |
| [`arquitectura.md`](arquitectura.md) | Estructura de carpetas, capas, Firebase y gestión de estado |
| [`pantallas.md`](pantallas.md) | Pantallas y navegación (enlazadas al mockup de Figma) |
| [`modelo_datos.md`](modelo_datos.md) | Entidades: jugador, sala, partida, etc. |
| [`map_shop_items.md`](map_shop_items.md) | Tiendas del mapa, mochila e ítems de la partida |
| [`results_system.md`](results_system.md) | Pantalla de resultados, XP y qué se guarda al terminar la partida |
| [`disconnections.md`](disconnections.md) | Presencia, cambio de anfitrión, reconexión y limpieza de salas |
| [`arte_imagenes.md`](arte_imagenes.md) | Imágenes y capas del personaje, mapa, ícono y cómo se exportan |
| [`protocolo.md`](protocolo.md) | Protocolo de juego: qué versiones pueden jugar juntas y cuándo subirlo |
| [`decisiones.md`](decisiones.md) | Decisiones técnicas y por qué se tomaron (incluye la auditoría de seguridad, D-48) |
| [`progreso_desarrollo.md`](progreso_desarrollo.md) | Registro de cada bloque de trabajo y su estado |
| [`roles_y_ramas.md`](roles_y_ramas.md) | Roles del equipo, ramas de Git y reglas de trabajo |

Fuera de `docs/`: el [`README.md`](../README.md) de la raíz (cómo correr, probar y compilar) y [`rules_test/README.md`](../rules_test/README.md) (pruebas de las reglas de Firebase).

## Cómo leerlos

0. Para correr el proyecto, ve al `README.md` de la raíz.
1. Empieza por `diseno_juego.md` para entender qué es el juego.
2. Sigue con `arquitectura.md` para ver cómo está construida la app.
3. Usa `pantallas.md` y `modelo_datos.md` como referencia mientras desarrollas.
4. Consulta `decisiones.md` cuando te preguntes "¿por qué se hizo así?".

## Convenciones

- Lo marcado como **(por definir)** aún no está decidido.
- Lo marcado como **(propuesto)** es una sugerencia pendiente de confirmar por el equipo.
- Los nombres de archivo van en minúsculas y con guion bajo.