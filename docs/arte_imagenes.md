# Arte de Party Tricks: lista de imágenes

> Responsable del arte: **Isabella Amaya**. Programa de dibujo: Krita.
> Última actualización: 27 de octubre de 2026.
> Marca cada imagen con [x] cuando esté exportada y copiada en su carpeta.

## 1. Reglas para todas las imágenes

- **Un solo tamaño por imagen.** Dibuja en grande y exporta al tamaño de la tabla. No hacen falta carpetas `2.0x/` ni `3.0x/`; el código reduce la imagen y controla la memoria (`cacheWidth`). Si en un celular viejo va lento, se baja a 2x.
- **Formato:**
  - **PNG** si la imagen lleva transparencia.
  - **WebP con calidad 85** para fondos grandes sin transparencia.
- **Lienzo en Krita:** 72 ppp, RGB, 8 bits. Los ppp no importan en pantalla, solo los píxeles.
- **Estilo** (el que ya tienes):
  - Contorno negro grueso en todas las piezas, de **mínimo 2 px en el tamaño exportado**. Los fondos no llevan contorno.
  - Colores planos, con máximo 3 tonos por objeto: base, claro y oscuro.
  - Reutiliza los colores que ya tienes: el café, la piel, el azul del diamante y el dorado de la moneda. Si necesitas uno nuevo, anótalo, porque luego se pasa a `AppColors`.
- **Nombres:** en minúsculas, sin tildes ni espacios y con guion bajo. Las variantes se numeran con dos cifras, por ejemplo `plataforma_01.png`.
- **Ancla:** es el punto que el código usa para colocar la imagen. En Krita pon guías en ese punto.
- **Volteo:** no dibujes versiones al revés. El código voltea las imágenes.
- **Carpetas:** cada carpeta nueva se agrega a `pubspec.yaml` en `flutter: assets:`, porque Flutter no lee subcarpetas solo.

## 2. Estructura de carpetas

```
assets/
├── images/
│   ├── Fondo_Principal.webp       (rehacer, ver sección 3)
│   ├── Fondo_Carga.webp           (reexportar, ver sección 3)
│   ├── logo_arranque.png
│   ├── cofres/                    los 3 cofres
│   ├── juego/                     moneda, diamante y dados
│   ├── mapa/
│   │   ├── piezas/                plataformas, marcas, flecha, puentes y textura del camino
│   │   └── decoraciones/          flores, rocas, arbustos y árboles
│   ├── personaje/                 hojas de animación del personaje
│   ├── cosmeticos/
│   │   ├── camisa/  pantalon/  zapatos/  cabello/  ojos/  nariz/  boca/
│   │   └── miniaturas/
│   └── iconos/                    barra de navegación y marcador del jugador
├── maps/
│   └── mapa_01/                   mapa.json, fondo.webp y minimapa.webp (una carpeta por mapa)
└── icon/                          ícono de la app
```

## 3. Fondos

| Hecho | Archivo | Carpeta | Exportar a (px) | Formato | Notas |
|---|---|---|---|---|---|
| [ ] | `Fondo_Principal.webp` | `assets/images/` | 1080 × 2346 | WebP | El actual (440 × 956) se ve borroso en celulares de 1080 px. Mejor **redibujarlo**; si no, reescalarlo y repasar los bordes |
| [ ] | `Fondo_Carga.webp` | `assets/images/` | 1440 × 2560 | WebP | Mismo dibujo. Pon el logo y los textos en el **80 % central**, porque en celulares altos se recorta de los lados |
| [ ] | `fondo.webp` | `assets/maps/mapa_01/` | 1440 × 2160 | WebP | El mundo del mapa mide 2880 × 4320 y el código muestra el fondo al doble. Formas planas y suaves. Bajo los puentes se sugiere río o agua, con el azul de `Fondo_Principal` |

> Al pasar los fondos a WebP hay que cambiar en el código las rutas `Fondo_Principal.png` y `Fondo_Carga.png` por `.webp`.

## 4. Mapa: piezas reutilizables

Carpeta: `assets/images/mapa/piezas/`

- **Vista ¾**, como en los Zelda y Pokémon clásicos: se ve la cara de arriba de cada pieza y un poco de su frente.
- Las piezas de más abajo en la pantalla tapan a las de arriba.
- **Una sola plataforma sirve para todos los tipos de casilla.** El tipo se muestra con la marca que va encima.

| Hecho | Archivo | Lienzo (px) | Ancla | Notas |
|---|---|---|---|---|
| [ ] | `plataforma_01.png` | 384 × 320 | Centro (192, 160) | Pasto con silueta orgánica. Superficie de unos 330 × 200 centrada y borde frontal de tierra de unos 40 px |
| [ ] | `plataforma_02.png` | 384 × 320 | Centro (192, 160) | Otra silueta, con la misma huella |
| [ ] | `plataforma_03.png` | 384 × 320 | Centro (192, 160) | Otra silueta |
| [ ] | `plataforma_04.png` | 384 × 320 | Centro (192, 160) | Otra silueta. Con el volteo, las 4 dan 8 aspectos |
| [ ] | `marca_inicio.png` | 192 × 192 | Centro inferior | Casilla de inicio |
| [ ] | `marca_negativa.png` | 192 × 192 | Centro inferior | Casilla mala |
| [ ] | `marca_especial.png` | 192 × 192 | Centro inferior | Casilla especial |
| [ ] | `marca_tienda.png` | 256 × 256 | Centro inferior | Tienda del mapa |
| [ ] | `flecha_bifurcacion.png` | 128 × 128 | Centro | Apunta a la **derecha**. El código la gira hacia cada camino |
| [ ] | `puente_horizontal.png` | 448 × 192 | Centro | Solo decorativo |
| [ ] | `puente_vertical.png` | 192 × 448 | Centro | Se dibuja aparte porque girarlo deforma la perspectiva |
| [ ] | `puente_diagonal.png` | 384 × 384 | Centro | Sirve para las dos diagonales con volteo |
| [ ] | `textura_camino.png` | 256 × 256 | — | Tierra que se repite sin cortes en los 4 lados. Usa el café de tus puentes y un tono más oscuro para piedritas y grietas, **sin contorno**. El código traza el contorno negro del caminito y lo rellena con esta textura |

- **Casilla positiva:** no tiene marca propia. Lleva encima la **moneda** (sección 6), y el código hace su animación (crece, sube y desaparece solo para ti).
- **Plantilla en Krita:** lienzo de 384 × 320 con guías en x = 192 e y = 160. Las 4 plataformas en el mismo archivo, una por capa.
- **Ancho del caminito:** cerca de la mitad del ancho de una plataforma. Sus extremos quedan tapados por las plataformas.

## 5. Mapa: decoraciones y minimapa

Carpeta: `assets/images/mapa/decoraciones/`. Todas con el **ancla en el centro inferior**, que es donde tocan el suelo.

| Hecho | Archivo | Lienzo (px) |
|---|---|---|
| [ ] | `deco_flor_01.png` a `deco_flor_03.png` (3) | 128 × 128 |
| [ ] | `deco_roca_01.png` a `deco_roca_03.png` (3) | 160 × 160 |
| [ ] | `deco_arbusto_01.png` y `deco_arbusto_02.png` (2) | 192 × 192 |
| [ ] | `deco_arbol_01.png` a `deco_arbol_03.png` (3) | 256 × 384 |

| Hecho | Archivo | Carpeta | Tamaño (px) | Formato | Notas |
|---|---|---|---|---|---|
| [ ] | `minimapa.webp` | `assets/maps/mapa_01/` | 512 × 512 | WebP | Versión reducida del mapa completo |
| [ ] | `marcador_jugador.png` | `assets/images/iconos/` | 96 × 96 | PNG | Marco circular para la foto de cada jugador en el minimapa |
| [ ] | `mapa.json` | `assets/maps/mapa_01/` | — | JSON | Posición de casillas, puentes y decoraciones. Se arma en **Tiled** (gratis) y un script lo convierte |

El mapa tiene 42 casillas:
- un camino principal cíclico, de la 0 a la 29;
- 3 caminos alternos (30-33, 34-37 y 38-41) que salen en las casillas 5, 15 y 24 y vuelven en la 10, 20 y 29.

Los caminos alternos miden lo mismo que el principal: dibújalos como ruta paralela (desvío o isla), no como atajo recto.

## 6. Elementos del juego

| Hecho | Archivo | Carpeta | Exportar a (px) | Notas |
|---|---|---|---|---|
| [ ] | `Cofre_Basico.png`, `Cofre_Party.png`, `Cofre_Diamante.png` | `assets/images/cofres/` | 512 × 512 | Ya existen a 1080. Recorta el margen vacío y reduce |
| [ ] | `moneda.png` | `assets/images/juego/` | 256 × 256 | Ya la tienes a 1080; solo reduce |
| [ ] | `diamante.png` | `assets/images/juego/` | 384 × 384 | Ya lo tienes a 1080; solo reduce |
| [ ] | `dado_1.png` a `dado_6.png` | `assets/images/juego/` | 192 × 192 cada uno | Una imagen por cara |

## 7. Personaje

Carpeta: `assets/images/personaje/`

- **Tamaño:** cada frame se **dibuja a 512 × 768** y se **exporta a 256 × 384**. Así los bordes salen limpios y queda espacio arriba para los brazos levantados.
- **Hojas:** una sola fila por hoja, frames del mismo tamaño, sin espacio entre ellos y mirando a la **derecha** (la izquierda se logra volteando).
- **Proporción:** la de tu `Bodysheet.kra`: cabeza enorme (casi la mitad de la altura), ojos de óvalo negro, nariz y boca mínimas.
- **En el mapa:** el código lo dibuja al 70 %; no hace falta otro tamaño.

| Hecho | Archivo | Frames | Tamaño de la hoja (px) |
|---|---|---|---|
| [ ] | `personaje_caminar.png` | 6 | 1536 × 384 |
| [ ] | `personaje_reposo.png` | 4 | 1024 × 384 |
| [ ] | `personaje_celebrar.png` | 6 | 1536 × 384 |
| [ ] | `personaje_negativa.png` | 4 | 1024 × 384 |

> Para la animación usa la línea de tiempo de Krita y **Animación → Renderizar como secuencia de imágenes**. Luego los frames se unen en una hoja.

## 8. Cosméticos

| Hecho | Archivo | Carpeta | Tamaño (px) |
|---|---|---|---|
| [ ] | `camisa_01`, `camisa_02` | `assets/images/cosmeticos/camisa/` | Frames de 256 × 384, mismo lienzo del personaje |
| [ ] | `pantalon_01`, `pantalon_02` | `assets/images/cosmeticos/pantalon/` | Igual |
| [ ] | `zapatos_01`, `zapatos_02` | `assets/images/cosmeticos/zapatos/` | Igual |
| [ ] | `cabello_01`, `cabello_02` | `assets/images/cosmeticos/cabello/` | Igual |
| [ ] | `ojos_01`, `ojos_02` | `assets/images/cosmeticos/ojos/` | Igual |
| [ ] | `nariz_01`, `nariz_02` | `assets/images/cosmeticos/nariz/` | Igual |
| [ ] | `boca_01`, `boca_02` | `assets/images/cosmeticos/boca/` | Igual |
| [ ] | Una miniatura por cosmético (14), con el mismo nombre | `assets/images/cosmeticos/miniaturas/` | 128 × 128 |

> **Pendiente antes de dibujar los cosméticos:** la ropa necesitaría un frame por cada frame de caminata, y eso es mucho trabajo. Hay que decidir cómo hacerlo (ropa por frames o piezas que siguen al cuerpo) cuando se trabaje la personalización.

## 9. Interfaz e ícono de la app

| Hecho | Archivo | Carpeta | Tamaño (px) | Notas |
|---|---|---|---|---|
| [ ] | `nav_inicio.png`, `nav_tienda.png`, `nav_vestuario.png`, `nav_stats.png`, `nav_amigos.png` | `assets/images/iconos/` | 96 × 96 | Barra de navegación. Si el activo cambia de dibujo, agrega `_activo` |
| [ ] | `icono_app.png` | `assets/icon/` | 1024 × 1024 | **Sin transparencia** (lo exige iOS) y sin esquinas redondeadas |
| [ ] | `icono_android_fondo.png` | `assets/icon/` | 1024 × 1024 | Capa de fondo del ícono de Android |
| [ ] | `icono_android_frente.png` | `assets/icon/` | 1024 × 1024 | Transparente. El dibujo va dentro del **círculo central de 660 px** |
| [ ] | `logo_arranque.png` | `assets/images/` | 1152 × 1152 | Transparente. Lo importante va dentro de un círculo de 768 px (regla de Android 12) |

Los botones y los marcos se siguen haciendo con Flutter, porque ya respetan `AppColors`. Dibuja a mano solo lo que quieras que se vea muy propio. Los tamaños del ícono se generan con el paquete `flutter_launcher_icons`.

## 10. Organización en Krita

- Un `.kra` por grupo:
  - mapa (plataformas, marcas y puentes);
  - decoraciones;
  - personaje;
  - cosméticos;
  - interfaz;
  - uno por cada fondo.
- **Capas con el nombre final del archivo**, por ejemplo `plataforma_01`.
- **Exportar:** usa **Herramientas → Scripts → Exportar capas**. Deja **desactivado** "recortar a la capa", para que cada pieza conserve su lienzo y encaje en el mismo ancla.

## 11. Resumen

| Grupo | Imágenes |
|---|---|
| Fondos | 3 |
| Piezas del mapa | 13 |
| Decoraciones | 11 |
| Minimapa y marcador | 2 |
| Cofres, moneda, diamante y dados | 11 (5 son solo reexportar) |
| Personaje | 4 hojas |
| Cosméticos y miniaturas | 14 + 14 |
| Barra de navegación | 5 |
| Ícono y logo de arranque | 4 |

## 12. Orden recomendado

1. Plataformas, textura del camino y marcas, para probar el mapa con tus dibujos.
2. Fondo del mapa, puentes y decoraciones.
3. Reexportar cofres, moneda y diamante. Dibujar los dados.
4. Hojas del personaje.
5. Fondos de la app (`Fondo_Principal` y `Fondo_Carga`).
6. Cosméticos y miniaturas, después de decidir cómo se anima la ropa.
7. Barra de navegación, ícono de la app y logo de arranque.

## 13. Decisiones tomadas

- El mapa se dibuja con widgets de Flutter (`InteractiveViewer` + `Stack`), no con Flame. Flame queda para los minijuegos (`decisiones.md`, D-11). **Hay que confirmarlo con Brayan.**
- Cada mapa se describe en `assets/maps/<mapa>/mapa.json` y de ahí se construye el tablero. El anfitrión sortea el mapa de cada partida.
- El caminito entre casillas lo traza el código con tu `textura_camino`.
- El mundo mide 2880 × 4320. Cada jugador ve solo su propio personaje; los demás aparecen en el minimapa.
- **Para Brayan:** el código del mapa toca `board_layout.dart` (que pasa a leer el JSON) y `board_screen.dart`, que son de su rama. Hay que avisarle antes de empezar, en la rama `feature/mapa-dibujado`.

## 14. Preguntas abiertas

- [ ] ¿Qué es `AS.kra` (3072 × 3072, 79 capas)?
- [ ] Con la **foto** del jugador, ¿se ocultan cabello, ojos, nariz y boca, o el cabello queda encima de la foto?
- [ ] ¿El **contorno blanco tipo sticker** va solo en portadas o también sobre el personaje en el mapa?
- [ ] ¿Cómo se anima la ropa: un frame por cada frame del cuerpo, o piezas que siguen al cuerpo?
- [ ] ¿Firebase Storage está disponible en el plan Spark? Si no, la foto de la cara se guarda reducida a 128 × 128 dentro de `users/{uid}` en Firestore.