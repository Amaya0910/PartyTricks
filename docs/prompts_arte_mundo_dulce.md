# Mundo Dulce: dirección de arte y prompts de producción

Documento de referencia para generar el arte final de Mundo Dulce (`mapa_dulces`, tema `dulces`). Tiene la dirección artística aprobada, los prompts de cada asset y las notas para integrarlos en el juego.

**Regla de oro:** el escenario siempre va detrás del juego. Fichas, casillas y UI se leen antes que cualquier decoración.

> No reinterpretar, simplificar ni cambiar colores o estilo sin actualizar primero este documento.

---

## Índice

1. [Dirección artística aprobada](#1-dirección-artística-aprobada)
2. [Reglas comunes de generación](#2-reglas-comunes-de-generación)
3. [Fondo](#3-fondo)
4. [Preview](#4-preview)
5. [Textura del camino](#5-textura-del-camino)
6. [Marcas de casilla](#6-marcas-de-casilla)
7. [Diamante](#7-diamante)
8. [Trampa](#8-trampa)
9. [Flecha de bifurcación](#9-flecha-de-bifurcación)
10. [Plataformas](#10-plataformas)
11. [Tiendas](#11-tiendas)
12. [Observaciones de integración](#12-observaciones-de-integración)
13. [Checklist de aprobación](#13-checklist-de-aprobación)

---

## 1. Dirección artística aprobada

### Concepto

**"Una pastelería-diorama a la hora dorada."** Un mundo de juguete hecho de dulces artesanales, iluminado por un sol cálido de tarde, donde cada zona es un postre distinto pero todas salen de la misma cocina.

**Los tres pilares:**

1. **Legible antes que bonito.** El tablero, las fichas y la UI van primero.
2. **Apetitoso, no pegajoso.** Materiales limpios y brillos controlados.
3. **Una sola cocina.** La misma luz, sombra, contorno y escala en las nueve zonas.

### Estilo artístico

**Cartoon estilizado en 3D "de juguete premium", con acabado de render suave.** Un diorama de dulces hecho a mano, como figuras de vinilo o pastelería fina miniatura.

- **No es semi-realista.** Las texturas realistas de comida (migas, grasa, brillo húmedo) se ven pegajosas en pantalla chica.
- **No es plano 2D ni vectorial.** Se ve barato al lado del tablero.
- **Proporciones:** formas redondeadas y algo exageradas, unas 1,5 veces más gruesas que en la realidad. No hay esquinas afiladas: todo tiene bisel o radio.
- **Vista:** isométrica o cenital inclinada (unos 35–45°), igual para todas las zonas.
- **Detalle:** poco y grande. Tiene que leerse a 360 px de ancho.
- **Público de 10 a 30 años:** divertido y apetitoso sin ser infantil. No hay caras en los dulces y los colores son saturados pero controlados.

### Paleta principal: la identidad del mapa

| Rol | Hex | Uso |
|---|---|---|
| Rosa fresa (base) | `#F9D6E3` | suelo general (`AppColors.candyGround`) |
| Caramelo (camino) | `#E2A66B` | caminos y conexiones (`AppColors.candyPath`) |
| Frambuesa (acento) | `#E0457B` | marca del mapa, banderines, detalles de prestigio (`AppColors.candyAccent`) |
| Crema vainilla | `#FFF4E0` | bordes, nata, glaseado, luces |
| Menta | `#9FE3CF` | vegetación dulce, aire y frescura |

**Proporción de uso: 60 / 25 / 10 / 5.**

- 60%: base rosa y crema.
- 25%: caramelo y chocolate de las estructuras.
- 10%: menta y cielo.
- 5%: acento frambuesa.

### Paleta secundaria: identidad de cada zona

| Zona | Dominante | Apoyo |
|---|---|---|
| Plaza de Caramelo | dorado caramelo `#F2B544` | crema `#FFF4E0` |
| Bosque de Piruletas | lila `#C9A7F5` | menta `#9FE3CF` |
| Reino de Chocolate | chocolate con leche `#7A4A2E` | oro `#E8C170` |
| Túnel de Galleta | galleta tostada `#D9A066` | sombra `#8C5A34` |
| Cumbres de Helado | celeste helado `#BDE7FF` | pistacho `#C8E6A0` |
| Avenida de Gomitas | naranja gomita `#FF9F5A` | limón `#FFE066` |
| Río de Caramelo | caramelo líquido `#E38A3A` | brillo `#FFD08A` |
| Cascada de Malvavisco | blanco rosado `#FFE9F2` | celeste `#CFEFFF` |
| Muelle de Chicle | chicle rosa `#FF8CC6` | chicle azul `#7FD3FF` |

**Regla:** dentro de una zona, el color de otra zona solo aparece en las transiciones (bordes entre zonas). Nunca se mezclan en el centro de una zona.

### Paleta de contraste: solo para el juego

Estos colores quedan **reservados** y no se usan en la decoración:

| Uso | Hex | Origen |
|---|---|---|
| Casilla positiva | `#66BB6A` | `AppColors.tilePositive` |
| Casilla negativa | `#E57373` | `AppColors.tileNegative` |
| Casilla especial | `#BA68C8` | `AppColors.tileSpecial` |
| Trampa | `#424242` | `AppColors.trap` |
| Jugadores | `#D32F2F` `#1976D2` `#388E3C` `#FBC02D` `#7B1FA2` `#F57C00` | `AppColors.playerColors` |
| Tinta de contorno y UI | `#3B2218` (chocolate oscuro, nunca negro puro) | — |
| Interacción, resaltado y diamante | `#45C7FF` (y `#139BFF` para sombra) | `AppColors.blueMain` y `blueStrong` |
| Resaltado | `#FFFFFF` con halo | — |

⚠️ **Alerta:** la casilla negativa (`#E57373`) se parece mucho a los rosas del mapa. Se resuelve con el **anillo chocolate `#3B2218` del set más el ícono**, el mismo que llevan todas las marcas. La información nunca depende solo del color.

### Materiales

| Material | Aspecto | Dónde |
|---|---|---|
| Fondant (mate y suave) | superficie lisa con un poco de brillo | suelos, plataformas y la mayoría de superficies |
| Caramelo duro (translúcido) | brillo marcado, se ve la luz por dentro | piruletas, cristales, lámparas, flechas, diamante |
| Chocolate (satinado) | brillo medio y bordes templados | Reino de Chocolate y estructuras de peso |
| Galleta (porosa) | textura de puntitos muy sutil, bordes horneados | túnel, cimientos, muros, tablones |
| Glaseado o nata (cremoso) | goteos redondeados | remates de techos y bordes de plataforma |
| Gomita (gelatinosa) | semitransparente, colores vivos | Avenida, señales, obstáculos |
| Malvavisco (esponjoso) | mate total, poros suaves | nubes, cascada, almohadillas |
| Chicle (elástico) | brillo plástico, forma estirada | muelle, cuerdas, burbujas |

**Reglas de material:**

- Como máximo **dos materiales protagonistas por zona.**
- Lo brillante atrae la mirada y lo mate la descansa. **Lo mate es al menos el 70% de la pantalla.**
- Las chispas de colores (sprinkles) se usan con moderación. Son el ruido visual número uno del género.

### Iluminación

- **Una sola luz principal:** cálida, de media tarde dorada (`#FFE8C2`), desde **arriba a la izquierda**.
- **Luz de relleno:** fría y suave, lavanda (`#E8D9FF`), desde la derecha.
- **Contraluz (rim light):** fino y crema en los bordes de los objetos importantes.
- **Oclusión ambiental:** suave en las uniones, para dar peso de juguete físico.
- **Brillo interno (glow):** solo en materiales translúcidos y en elementos interactivos.
- **Todas las zonas tienen la misma luz.** El Túnel puede tener faroles de caramelo, pero el tablero no se oscurece.

### Sombras

- **Dirección fija:** hacia **abajo a la derecha**, unos 45°, sin excepción.
- **Color:** chocolate violáceo `#5A3550` con 25–35% de opacidad. **Nunca gris ni negro.**
- **Cortas**, porque el sol está alto: no tapan casillas vecinas.
- **Prohibido** que la sombra de un edificio caiga sobre una casilla o sobre el camino.
- **Fichas de jugador:** sombra de contacto más oscura (40–50%), para que floten sobre el entorno.

### Reglas para íconos

- **Forma primero:** la silueta en negro sólido se reconoce a 24 px.
- **Contorno chocolate `#3B2218`**, de grosor fijo (unos 2 px a 48 px de tamaño, que escala proporcional). Es obligatorio en las marcas, la flecha, el diamante y la trampa. Es una excepción aprobada a `docs/arte_imagenes.md` (ver la [sección 12](#excepción-aprobada-a-docsarte_imagenesmd-contorno-chocolate)).
- **Volumen:** dos tonos (luz y sombra) más un brillo. Sin degradados complejos.
- **Dentro de un cuadrado redondeado o un círculo** con fondo crema.
- **Los íconos de casilla no son decoración:** usan los colores reservados y comparten un mismo set visual.
- **Una idea por ícono.** Nada de texto, números pequeños ni escenas.
- El tema se puede sugerir, pero el significado tiene que ser universal (+, −, ★, ⚠).

### Reglas para edificios

- **Decorados de borde**, no van en el camino. Ocupan como máximo de 2 a 3 casillas de ancho visual.
- **Silueta única por edificio.**
- **Estructura en tres capas:** base pesada (galleta o chocolate), cuerpo (fondant) y remate (glaseado, piruleta o cereza).
- **Ventanas y puertas grandes y simples**, sin herrajes finos.
- **Ligeramente deformados** (efecto squash), nunca rectos y rígidos.
- **Saturación menor que la del tablero.**
- **Sin letreros con texto** dentro del arte.

### Reglas para plataformas

- **Forma base:** galleta o fondant redondeado, con un **canto lateral visible**.
- **Borde de glaseado crema** que separa la casilla del suelo rosa.
- **La cara superior es plana, limpia y crema.** El color lo pone la marca.
- **El tamaño es el mismo en todo el mapa.** Solo cambia el material del canto.
- **El camino** va al ras del suelo, nunca por encima de las casillas.
- **Las bifurcaciones** se marcan con un elemento guía (anillo y flecha), nunca solo con el color.
- **Sobre líquidos:** puentes o rocas de caramelo duro, con un borde muy claro respecto al líquido.

### Errores visuales a evitar

1. Exceso de saturación en todo.
2. Confeti y sprinkles por todas partes.
3. Rosa sobre rosa: que las casillas y los acentos se pierdan en el suelo.
4. Usar los colores reservados en la decoración.
5. Comida que se ve real o sucia: chocolate como barro, gomitas babosas, grasa.
6. Sombras grises o negras.
7. Iluminación distinta por zona.
8. Detalles finos: líneas de 1 px, texto, patrones que hacen moiré.
9. Elementos altos delante del camino que tapan casillas o fichas.
10. Estilos mezclados: un asset plano junto a uno renderizado, o contornos de grosores distintos.
11. Infantilizar: caritas en todo y una paleta solo pastel sin contraste.
12. Que el fondo compita con la UI.

### Jerarquía visual (del que más resalta al que menos)

1. Fichas de jugador
2. Casillas y sus íconos
3. Camino, bifurcaciones y flechas
4. Elementos interactivos y animados (diamante, trampas)
5. Edificios y puntos de referencia
6. Suelo y decoración
7. Cielo y fondo

### Zonas

El tablero tiene forma de "ojo" (`lib/services/map/boards/mapa_dulces.dart`). La Plaza (casillas 0–4) llega a la bifurcación 4, que abre un **lóbulo norte** (5–26) y un **lóbulo sur** (32–48). Los dos vuelven a la casilla 27, y la **Avenida de Gomitas** (27–31) cierra la vuelta en la salida.

| Zona | Ubicación | Descripción |
|---|---|---|
| Plaza de Caramelo | centro, salida (0–4) | quiosco y fuente de caramelo dorado; la zona más cálida y acogedora |
| Avenida de Gomitas | centro, cierre (27–31) | farolas y señales de gomita naranja y limón; la más enérgica y "urbana" |
| Bosque de Piruletas | lóbulo norte | piruletas en espiral como árboles, lila y menta, luz filtrada |
| Reino de Chocolate | lóbulo norte | castillo de chocolate con leche y oro; la zona más "premium" |
| Túnel de Galleta | atajo norte (11 → 49…53 → 20) | arco de galleta tostada con faroles de caramelo; acogedor, nunca oscuro |
| Cumbres de Helado | extremo norte | montañas de bolas de helado celeste y pistacho, azúcar glas |
| Río de Caramelo | lóbulo sur | caramelo líquido brillante con puentes de caramelo duro |
| Cascada de Malvavisco | atajo sur (37 → 54…59 → 45) | cascada esponjosa blanca y rosada con nubes de azúcar |
| Muelle de Chicle | extremo sur | tablones de galleta con barcos y boyas de chicle rosa y azul |

> La ubicación exacta de cada zona se valida contra `assets/maps/mapa_dulces/mapa.tmj` antes de pintar el fondo.

---

## 2. Reglas comunes de generación

### Contexto obligatorio (va igual al inicio de cada prompt)

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text.
```

### Prompt negativo común (se agrega a todos los assets)

```
text, letters, numbers, watermark, logo, signature, realistic food photography, greasy, wet, sticky, melted mess, dirty, grey or black shadows, pure black outlines, thin 1px lines, tiny details, noisy sprinkles everywhere, confetti clutter, faces on candy, baby style, flat vector, pixel art, harsh rim lighting, dark scene, horror, blur, low resolution, jpeg artifacts
```

### Transparencia

La mayoría de los generadores no exportan alfa real. Para los assets transparentes:

1. Genera sobre `plain flat solid neutral grey background (#808080)`. La trampa es la excepción y va sobre crema `#FFF4E0`.
2. Quita el fondo después y revisa los bordes: sin halo gris ni píxeles semitransparentes sueltos.
3. **No uses verde ni magenta como croma**, porque chocan con la marca positiva y con los rosas.

### Resolución

- Genera siempre a **2× o 4×** del tamaño final y reduce con Lanczos.
- Los tamaños de cada ficha son los **finales en el repo**.
- **Ninguna imagen puede pasar de 4096 px de lado** (`docs/arte_imagenes.md`, las pruebas lo revisan).

### Orden de producción

1. `plataforma_01.png`, que fija la forma de todas las plataformas.
2. Marcas de casilla, `marca_bifurcacion.png` y `flecha_bifurcacion.png`, que fijan el lenguaje de íconos.
3. `diamante.png` y `trampa.png`.
4. `plataforma_02`, `plataforma_03` y `plataforma_04`, derivadas de la 01.
5. Las tres tiendas.
6. `textura_camino.png`.
7. `fondo.png`, con el tablero ya armado en Tiled.
8. `preview.png`, sacada del juego o de Tiled con todo el arte final.

---

## 3. Fondo

### fondo.png

| Campo | Valor |
|---|---|
| Ruta | `assets/maps/mapa_dulces/fondo.png` |
| Resolución final | **1440 × 3200** (vertical, 9:20). El mundo mide 2880 × 6400 y el código muestra el fondo al doble |
| Transparencia | No |

**Prompt:**

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. Tall vertical game board background of a candy world shaped like a large eye-shaped loop of open ground. Base ground of smooth matte strawberry-pink fondant (#F9D6E3) with soft vanilla cream (#FFF4E0) frosting edges. Center band: Caramel Plaza with golden caramel (#F2B544) cobblestone floor and a small caramel fountain at the side, and Gummy Avenue with orange (#FF9F5A) and lemon (#FFE066) gummy lamp posts. Northern lobe: Chocolate Kingdom with milk chocolate (#7A4A2E) hills and gold (#E8C170) accents, Lollipop Forest with lilac (#C9A7F5) and mint (#9FE3CF) swirl lollipop trees, a Cookie Tunnel arch of toasted cookie (#D9A066), and Ice Cream Peaks in the far top with sky-blue (#BDE7FF) and pistachio (#C8E6A0) scoop mountains. Southern lobe: a glossy translucent Caramel River (#E38A3A with #FFD08A highlights) curving through, a fluffy Marshmallow Waterfall in white-pink (#FFE9F2) and pale blue (#CFEFFF), and a Bubblegum Pier of cookie planks with pink (#FF8CC6) and blue (#7FD3FF) gum boats at the bottom. Each zone keeps its own dominant color, mixing only at soft transitions. Large calm open ground areas where the board will be placed, decorations pushed to the outer edges, low contrast and slightly pastel away from the play area.
```

**Obligatorio:**

- Las nueve zonas, ubicadas en el orden norte, centro y sur.
- Suelo amplio y despejado donde irá el tablero.
- Las transiciones entre zonas solo en los bordes.
- Las paletas de zona exactas.

**Prohibido:**

- Caminos, casillas, plataformas, flechas, íconos, diamantes, personajes o fichas.
- Elementos altos en la zona de juego.
- Verde `#66BB6A`, rojo `#E57373` y morado `#BA68C8` en la decoración.

**Observaciones para Party Tricks:**

- **Antes de generar, verifica en `mapa.tmj` la posición real de cada lóbulo.** Exporta el tablero desde Tiled (**Archivo → Exportar como imagen**) y úsalo como guía de composición (img2img o ControlNet con baja influencia).
- El código pinta el camino (`#E2A66B`, 160 px de ancho del mundo). El suelo bajo el camino debe ser liso.
- Los generadores no sacan 9:20 en alta resolución. Genera en tres tramos (norte, centro y sur) o como 9:16 con outpainting vertical, y une y escala a 1440 × 3200.
- **No lo subas a 2880 × 6400:** pasa el límite de 4096 px y ocuparía unos 73 MB de GPU. Si algún día hace falta más detalle, se parte en trozos con la capa `fondo` de Tiled (ver `docs/arte_imagenes.md`).

---

## 4. Preview

### preview.png

| Campo | Valor |
|---|---|
| Ruta | `assets/maps/mapa_dulces/preview.png` |
| Resolución final | **480 × 1067**, la misma proporción que el mundo |
| Transparencia | No |

**Prompt** (solo si todavía no hay arte final para sacar la captura):

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. Miniature overview of the entire Candy World board: eye-shaped loop with a caramel (#E2A66B) path connecting small cream-bordered cookie platforms, Caramel Plaza and Gummy Avenue in the middle, Chocolate Kingdom castle and lollipop trees in the northern lobe, glossy Caramel River and marshmallow waterfall in the southern lobe. Strawberry-pink (#F9D6E3) ground, raspberry (#E0457B) accent flags. Very simple, bold shapes, readable as a thumbnail, inviting and premium.
```

**Obligatorio:**

- La forma de "ojo" reconocible.
- Los dos lóbulos diferenciados: chocolate arriba, río abajo.
- El acento frambuesa como marca del mapa.

**Prohibido:**

- Texto o el nombre del mapa (lo pone la UI).
- Fichas de jugador.
- Más detalle que el fondo.

**Observaciones para Party Tricks:**

- **La opción recomendada es no generarla.** Exporta desde Tiled con el fondo final y todas las piezas (**Archivo → Exportar como imagen**) y reduce a 480 px de ancho. Así coincide con lo que se juega, igual que la de `mapa_01`.
- Las pruebas exigen que cada mapa tenga su preview.

---

## 5. Textura del camino

### textura_camino.png

| Campo | Valor |
|---|---|
| Ruta | `assets/themes/dulces/textura_camino.png` |
| Resolución final | **256 × 256**, repetible en los dos ejes |
| Transparencia | No |

**Prompt:**

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. Seamless tileable texture viewed straight from above, flat orthographic surface: smooth glossy caramel road (#E2A66B) with very subtle large soft swirls and gentle toasted tones, low contrast, even lighting across the whole tile, no visible seams, no objects.
```

**Obligatorio:**

- Seamless en X e Y.
- Contraste muy bajo.
- El tono medio exacto `#E2A66B`.

**Prohibido:**

- Sombras proyectadas, objetos o sprinkles.
- Patrones pequeños que hagan moiré.
- Bordes, viñeteado o un punto de luz que delate la repetición.

**Observaciones para Party Tricks:**

- **Excepción técnica a la vista isométrica:** una textura que se repite tiene que ser cenital y plana. La luz cálida se mantiene, pero sin sombra direccional, porque el camino gira y la sombra rotaría con él.
- Valídala repitiéndola 3 × 3 antes de aprobarla.

---

## 6. Marcas de casilla

### Reglas comunes

| Campo | Valor |
|---|---|
| Ruta | `assets/themes/dulces/` |
| Resolución final | **192 × 192** |
| Transparencia | Sí |

- **Vista casi cenital:** se dibujan encima de la cara plana de la plataforma, así que no pueden tener perspectiva fuerte.
- **Forma:** disco de fondant con borde de glaseado crema `#FFF4E0`, contorno chocolate `#3B2218` de grosor fijo, e ícono centrado con dos tonos más un brillo.
- **Margen:** unos 8 px libres hasta el borde del lienzo.
- **La silueta se lee a 24 px.**
- **Las seis marcas comparten disco, borde, contorno y grosor.** Solo cambian el color y el ícono.

### marca_inicio.png

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. Game board start tile token seen almost from directly above: round raspberry (#E0457B) fondant disc with thick vanilla cream (#FFF4E0) frosting rim and a uniform dark chocolate (#3B2218) outline, centered bold cream-white waving flag icon on a caramel stick, simple two-tone shading with one glossy highlight, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** frambuesa `#E0457B`, que es la identidad del mapa, y una bandera grande.
- **Prohibido:** colores reservados de casilla; estrellas, que pertenecen a la casilla especial.
- **Observaciones:** es la única marca con el color de marca del mapa, para que se distinga de las demás. Va en la casilla 0.

### marca_positiva.png

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. Game board positive tile token seen almost from directly above: round green (#66BB6A) fondant disc with thick vanilla cream (#FFF4E0) frosting rim and a uniform dark chocolate (#3B2218) outline, centered bold chunky rounded plus sign made of cream hard candy, simple two-tone shading with one glossy highlight, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** verde exacto `#66BB6A` y signo **+** grueso.
- **Prohibido:** números, que la UI muestra aparte; monedas o diamantes dentro del ícono.
- **Observaciones:** es la marca más repetida del tablero, así que tiene que ser la más simple.

### marca_negativa.png

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. Game board negative tile token seen almost from directly above: round red (#E57373) fondant disc with thick vanilla cream (#FFF4E0) frosting rim and a uniform dark chocolate (#3B2218) outline, same ring as the rest of the marker set, centered bold chunky rounded minus sign made of cream hard candy, simple two-tone shading with one glossy highlight, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** rojo exacto `#E57373`, signo **−** y **el mismo anillo chocolate que el resto del set**.
- **Criterio de aprobación (decisión aprobada):** que se lea sobre `#F9D6E3` y que sea consistente con las demás marcas. No es obligatorio que el anillo sea más grueso: el anillo chocolate común ya la separa del rosa.
- **Prohibido:** calaveras o imagen agresiva; bajar la saturación del rojo.
- **Observaciones:** prueba la marca sobre `#F9D6E3`. Si se confunde con el suelo a un brazo de distancia, recházala. Es la segunda más repetida (14 casillas).

### marca_especial.png

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. Game board special tile token seen almost from directly above: round purple (#BA68C8) fondant disc with thick vanilla cream (#FFF4E0) frosting rim and a uniform dark chocolate (#3B2218) outline, centered bold chunky five-point star made of translucent hard candy with a soft inner glow, simple two-tone shading with one glossy highlight, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** morado exacto `#BA68C8` y estrella **★** de caramelo duro **crema-blanco translúcido** con brillo interno y reflejos lavanda suaves.
- **Prohibido:** signos de interrogación o texto; **estrella dorada, amarilla o naranja**. A 24 px se confundía con el dorado de `marca_tienda.png` y rompía la regla de íconos crema del set.
- **Versión aprobada** (la v1 tenía la estrella dorada): se generó con este prompt, usando como referencia la v1 de la especial y `marca_positiva.png`:

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, no text. Round purple (#BA68C8) fondant board marker. Thick vanilla cream rim. Dark chocolate outline #3B2218. Large translucent cream-white hard-candy star. Soft internal glow. Subtle lavender highlights. Very readable at 24 px. Consistent with the positive, negative, shop and start markers. No gold. No yellow. No orange. No text.
```
- **Observaciones:** el brillo interno está permitido porque es una casilla interactiva y especial, como marca la regla de iluminación.

### marca_tienda.png

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. Game board shop tile token seen almost from directly above: round golden caramel (#F2B544) fondant disc with thick vanilla cream (#FFF4E0) frosting rim and a uniform dark chocolate (#3B2218) outline, centered bold simple shopping bag icon in cream with a rounded handle, simple two-tone shading with one glossy highlight, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** dorado caramelo `#F2B544` y bolsa de compras como ícono.
- **Prohibido:** naranja `#F57C00`, porque es color de jugador; signo $ o texto.
- **Observaciones:** aparece en las casillas 3, 16 y 41, junto a los tres edificios de tienda.

### marca_bifurcacion.png

| Campo | Valor |
|---|---|
| Resolución final | **192 × 192** (el código la muestra 1,3 veces más grande que la marca) |
| Transparencia | Sí, y el centro transparente |

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. Game board fork base ring seen almost from directly above: thin circular ring hugging the outer edge, made of translucent cyan (#45C7FF) hard candy with darker cyan (#139BFF) shading, a vanilla cream (#FFF4E0) inner edge and a uniform dark chocolate (#3B2218) outline, four small rounded notches pointing outward, the whole inside of the ring completely empty and transparent, soft inner glow, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:**
  - **El anillo vive solo en la franja exterior**, del 78% al 100% del diámetro.
  - El interior es transparente.
  - Cian `#45C7FF`, que es el color de interacción.
- **Prohibido:** íconos en el centro, colores de casilla o un anillo grueso que invada el interior.
- **Observaciones:**
  - Se dibuja **debajo** de la marca de la casilla, a 1,3 veces su tamaño (`MapScenery.forkMarkSize`, en `lib/widgets/map/map_scenery.dart`). La marca tapa el 77% central, así que **solo se ve el borde exterior**. Todo lo que quede dentro del 77% central no se ve.
  - Va en las casillas 4, 11 y 37. Pruébala con cada tipo de marca encima.
  - Comparte material, color y contorno con `flecha_bifurcacion.png`: son la misma "pieza de decisión".

---

## 7. Diamante

### diamante.png

| Campo | Valor |
|---|---|
| Ruta | `assets/themes/dulces/diamante.png` |
| Resolución final | **192 × 192** |
| Transparencia | Sí |

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A single chunky rounded gem-cut diamond made of translucent cyan (#45C7FF) hard candy, few large soft facets, bright inner glow, thin cream rim light, uniform dark chocolate (#3B2218) outline, small soft round purple-brown contact shadow below, floating slightly, isolated on a plain flat solid neutral grey background.
```

**Obligatorio:**

- Cian `#45C7FF`, que es `AppColors.diamond`.
- Pocas facetas y grandes.
- Silueta clásica de diamante.

**Prohibido:**

- Facetas finas o realistas.
- Destellos en estrella.
- Volverlo rosa o "de azúcar", porque tiene que ser el mismo diamante de toda la app.

**Observaciones para Party Tricks:**

- Es el objetivo de la partida. Junto con las fichas, es lo que más resalta del mapa.
- También se usa **dentro del indicador fuera de pantalla** (`_DiamondIndicator`), sobre un círculo blanco y con un 24% de relleno. Tiene que leerse a unos 40 px.
- La sombra de contacto se ve rara dentro del indicador. Si molesta, genera una versión sin sombra.

---

## 8. Trampa

### trampa.png

| Campo | Valor |
|---|---|
| Ruta | `assets/themes/dulces/trampa.png` |
| Resolución final | **192 × 192** |
| Transparencia | Sí (generar sobre crema `#FFF4E0`) |

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A cartoon snap trap made of dark grey licorice (#424242) with rounded chunky jaws and blunt candy-corn teeth, slightly open, cream hard-candy spring, uniform dark chocolate (#3B2218) outline, compact silhouette, small soft purple-brown contact shadow, playful but clearly a hazard, isolated on a plain flat solid vanilla cream (#FFF4E0) background.
```

**Obligatorio:**

- Gris oscuro `#424242`, que es `AppColors.trap`.
- Silueta de cepo reconocible.

**Exención aprobada de contorno:** la trampa no utiliza contorno chocolate porque el cuerpo principal `#424242` ya proporciona el contraste necesario y la legibilidad requerida a 18–24 px.

**Prohibido:**

- Sangre, metal realista o dientes afilados.
- Negro puro.

**Observaciones para Party Tricks:**

- Va sobre crema y no sobre gris porque el croma gris se acerca demasiado a `#424242` y el recorte falla.
- Se coloca sobre el camino, así que tiene que contrastar con el caramelo `#E2A66B`.

---

## 9. Flecha de bifurcación

### flecha_bifurcacion.png

| Campo | Valor |
|---|---|
| Ruta | `assets/themes/dulces/flecha_bifurcacion.png` |
| Resolución final | **128 × 128**, igual que la flecha clásica |
| Generación | a 512 × 512 o 1024 × 1024, reducida con Lanczos |
| Transparencia | Sí |
| Orientación | **apuntando a la derecha (0°)**, centrada |

**Cómo la usa el juego** (`_arrow`, en `lib/widgets/map/board_map_view.dart`):

- Se dibuja **dentro de un círculo** de `arrowBackground` (por defecto `AppColors.boardPanel`, blanco al 90%), con sombra suave y un **relleno del 10%**.
- El código **la rota** hacia cada rama con `atan2`. Por eso tiene que apuntar a la derecha, estar centrada y ser simétrica de arriba a abajo.
- Se escala con `BoxFit.contain` y **no se tiñe**: los colores del PNG son los finales.

**Proporciones** (medidas de la flecha clásica, `assets/images/mapa/piezas/flecha_bifurcacion.png`):

| Medida | Clásica (128 px) | Proporción | Mundo Dulce |
|---|---|---|---|
| Largo total | 104 px (x 12–116) | 81% del lienzo | igual |
| Alto de la punta | 62 px (y 33–95) | 48% del lienzo | igual |
| Grosor del cuerpo | 37 px (y 45–81) | 29% del lienzo | **igual: es el "mismo grosor visual"** |
| Margen | unos 12 px | — | igual |

**Prompt:**

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A single bold chunky game UI arrow pointing straight to the right, seen from the front, perfectly centered and vertically symmetrical: short thick straight shaft and a wide triangular arrowhead with softly rounded corners, made of translucent cyan (#45C7FF) hard candy with darker cyan (#139BFF) shading on the lower half, one soft vanilla cream (#FFF4E0) glossy highlight stripe along the top of the shaft and head, soft inner glow, uniform thick dark chocolate (#3B2218) outline around the whole shape, no cast shadow, simple two-tone shading, very simple silhouette readable at small size, isolated on a plain flat solid neutral grey background.
```

**Negativo adicional:**

```
curved arrow, double arrow, thin arrow, long thin shaft, arrow pointing up or diagonal, perspective, tilted, cast shadow, drop shadow, swirls, stripes like candy cane, sprinkles, lollipop stick, gradient rainbow, glitter, multiple arrows, background circle, frame, border, badge
```

**Obligatorio:**

- **Apunta exactamente a la derecha** y es simétrica en el eje horizontal.
- **Cuerpo de unos 37 px de grosor y punta de unos 62 px de alto** en el lienzo de 128, con unos 104 px de largo. Son las mismas proporciones que la flecha clásica.
- Caramelo duro cian `#45C7FF` con sombra `#139BFF`: el mismo material y color que `marca_bifurcacion.png`.
- Contorno chocolate `#3B2218` **grueso y uniforme**: unos 5 px a 128, que se mantienen en unos 2 px a 48.
- Un solo brillo crema arriba (la luz viene de arriba a la izquierda).

**Prohibido:**

- **Sombra proyectada.** El código ya le pone una al círculo y, al rotar, una sombra horneada apuntaría en otra dirección.
- **Círculo, placa o marco de fondo** dentro del PNG. Lo dibuja el código.
- Rayas de bastón de caramelo, remolinos, sprinkles, palito de piruleta.
- Flechas curvas, dobles, finas o en perspectiva.
- Los colores de casilla: verde, rojo y morado (la clásica es morada, pero **en este tema el morado es la casilla especial**).
- Frambuesa `#E0457B`, que se perdería sobre los rosas.

**Lectura sobre las zonas que pediste:**

La flecha siempre va sobre el círculo blanco, así que la legibilidad la deciden el contraste cian contra blanco y el contorno chocolate. Aun así, el conjunto se valida sobre cada zona:

| Zona | Riesgo | Qué asegura la lectura |
|---|---|---|
| Plaza de Caramelo (`#F2B544`) | el cálido puede apagar el círculo | el cian es complementario del dorado y el contorno chocolate cierra la forma |
| Bosque de Piruletas (`#C9A7F5`, `#9FE3CF`) | la menta está cerca del cian | el círculo blanco separa y la sombra `#139BFF` da más valor que la menta |
| Reino de Chocolate (`#7A4A2E`) | el contorno chocolate se funde con el suelo | el círculo blanco aísla el contorno; la flecha nunca toca el chocolate |
| Río de Caramelo (`#E38A3A`) | el brillo del río compite | cian contra naranja es el contraste máximo; la flecha no lleva glow exterior |
| Cascada de Malvavisco (`#FFE9F2`, `#CFEFFF`) | el círculo blanco se pierde sobre blanco y celeste | la sombra del círculo (`characterShadow`) y la flecha saturada con contorno oscuro |

**Prueba obligatoria antes de aprobar:**

1. Monta la flecha sobre el círculo blanco a **40, 56, 72 y 96 px**, con el 10% de relleno.
2. Pon cada tamaño sobre un recorte del fondo final de las cinco zonas.
3. Rótala a 0°, 45°, 90°, 135° y 180°. Tiene que verse igual de bien en todas.
4. **A 40 px** el círculo deja unos 32 px para la flecha: el contorno no puede desaparecer y la punta tiene que distinguirse del cuerpo.
5. Compárala con la clásica a 40 px. El grosor del cuerpo tiene que ser el mismo.

**Observaciones para Party Tricks:**

- Es la única pieza del tablero que **se toca**, así que va sobre la decoración en la jerarquía y comparte el cian de interacción con `marca_bifurcacion.png` y el diamante.
- Aparece en las bifurcaciones 4, 11 y 37, una por rama. Con dos flechas una al lado de la otra, la silueta tiene que ser compacta para que no se toquen.
- **Opcional, requiere un cambio de código:** el tema `candy` no define `arrowBackground`, así que usa el blanco clásico. Si con la Cascada de Malvavisco el círculo blanco se pierde, se puede dar al tema un círculo crema `#FFF4E0` en `MapThemeCatalog.candy` (`lib/services/map/map_theme.dart`). Ese cambio también afecta al indicador del diamante, que usa el mismo color.
- Sin este archivo, el tema toma la flecha clásica (morada) y la app lo avisa en el log.

---

## 10. Plataformas

### Reglas comunes

| Campo | Valor |
|---|---|
| Resolución final | **384 × 320**, el tamaño del tileset `casillas` en `mapa.tmj` |
| Transparencia | Sí |

- Pieza redondeada con el **canto lateral visible** (grosor).
- **Cara superior plana, lisa y crema** `#FFF4E0`, con borde de glaseado.
- La marca de 192 px va centrada en esa cara, así que la cara tiene que medir **al menos 250 px de ancho**. En las bifurcaciones, el anillo ocupa unos 250 px.
- **Solo cambia el material del canto.** La forma, el tamaño y la cara superior son idénticos en las cuatro.
- **Prohibido en todas:** íconos, colores de casilla o decoración sobre la cara superior; texturas en la cara; bordes que salgan del lienzo.
- **Método:** genera la 01 primero y úsala como referencia de forma (img2img, el mismo seed o una máscara de silueta) para las otras tres.

### plataforma_01.png: galleta (Plaza y uso general)

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A single round game board platform piece: thick toasted cookie (#D9A066) base with visible side thickness, subtle large-pore cookie texture and baked darker edges (#8C5A34), flat smooth vanilla cream (#FFF4E0) top face with a soft rounded frosting drip border, top face completely clean and empty, short soft purple-brown contact shadow to bottom-right, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** canto de galleta, cara crema y goteo de glaseado.
- **Observaciones:** es la plataforma base. Se usa en la Plaza, la Avenida y donde no haya una temática fuerte.

### plataforma_02.png: chocolate (Reino de Chocolate)

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A single round game board platform piece: thick satin milk chocolate (#7A4A2E) base with visible side thickness, smooth tempered edges and a thin gold (#E8C170) trim line, flat smooth vanilla cream (#FFF4E0) top face with a soft rounded frosting drip border, top face completely clean and empty, short soft purple-brown contact shadow to bottom-right, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** canto satinado y una línea de oro.
- **Prohibido:** chocolate derretido o con aspecto de barro.
- **Observaciones:** se usa en el lóbulo norte, alrededor del Reino.

### plataforma_03.png: helado (Cumbres de Helado y norte alto)

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A single round game board platform piece: thick base of soft scooped ice cream in sky blue (#BDE7FF) with a pistachio (#C8E6A0) layer, visible side thickness with rounded scoop ridges, a few soft melting drips kept clean and solid, flat smooth vanilla cream (#FFF4E0) top face with a soft rounded frosting border, top face completely clean and empty, short soft purple-brown contact shadow to bottom-right, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** canto celeste y pistacho, con crestas de bola.
- **Prohibido:** helado con aspecto húmedo o charcos.
- **Observaciones:** el "derretido" tiene que ser sólido y limpio.

### plataforma_04.png: gomita (Río, Cascada y Muelle)

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A single round game board platform piece: thick semi-translucent orange (#FF9F5A) gummy base with a lemon (#FFE066) layer, visible side thickness, soft gelatin glow where light passes through, flat smooth vanilla cream (#FFF4E0) top face with a soft rounded frosting border, top face completely clean and empty, short soft purple-brown contact shadow to bottom-right, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** canto de gomita semitransparente.
- **Prohibido:** aspecto baboso o pegajoso; naranja `#F57C00`, porque es color de jugador.
- **Observaciones:** es la que mejor contrasta con el rosa del sur. Sobre el Río de Caramelo, comprueba que no se confunda con el líquido: si pasa, usa la 01.

---

## 11. Tiendas

### Reglas comunes

| Campo | Valor |
|---|---|
| Resolución final | **448 × 448**, el tamaño del tileset `objetos`. La chocolatería admite 512 × 512 si necesita altura |
| Transparencia | Sí |

- **Estructura en tres capas:** base pesada, cuerpo de fondant y remate.
- **Silueta única por edificio.** Saturación algo menor que la del tablero.
- **Prohibido en las tres:** letreros con texto, herrajes finos, ventanas pequeñas, personajes, colores de casilla o de jugador.
- **Colocación:** **junto** a la casilla de tienda, nunca encima del camino. Su sombra no puede caer sobre una casilla.

| Edificio | Casilla | Zona |
|---|---|---|
| `tienda_plaza.png` | 3 | Plaza de Caramelo |
| `chocolateria.png` | 16 | lóbulo norte, Reino de Chocolate |
| `heladeria_rio.png` | 41 | lóbulo sur, Río de Caramelo |

### tienda_plaza.png

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A small chubby round candy kiosk for a town plaza: golden caramel (#F2B544) cobblestone base, vanilla cream (#FFF4E0) fondant walls, striped scalloped awning in raspberry (#E0457B) and cream, round dome roof topped with a big swirl lollipop, wide open counter with jars of simple oversized candies and warm glow, slightly squashed playful proportions, blank sign board with no text, short soft purple-brown contact shadow to bottom-right, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** quiosco redondo, toldo frambuesa y crema, piruleta en el techo.
- **Prohibido:** frascos con dulces pequeños y numerosos (usa pocos y grandes).
- **Observaciones:** es la primera tienda que ve el jugador, así que tiene que ser la más acogedora.

### chocolateria.png

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A small chubby chocolate shop building shaped like a mini castle tower: heavy cookie base, satin milk chocolate (#7A4A2E) walls with gold (#E8C170) trim, slightly squashed and leaning playful proportions, large simple arched door and two big round windows with warm glow, rounded chocolate bar roof tiles topped with vanilla cream (#FFF4E0) frosting drips and one raspberry (#E0457B) pennant flag, blank sign board with no text, short soft purple-brown contact shadow to bottom-right, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** silueta de torre o castillo, satinado, oro y el banderín frambuesa.
- **Prohibido:** chocolate derretido o sucio; almenas finas.
- **Observaciones:** es el edificio más "premium" del mapa. Tiene que verse más pequeño que el castillo del fondo para no competir con él.

### heladeria_rio.png

```
Stylized 3D cartoon candy diorama, premium mobile game art, soft toy-like rounded shapes, fondant and hard-candy materials, warm golden afternoon key light from top-left, soft lavender fill light, short soft purple-brown contact shadows to bottom-right, clean readable shapes, minimal fine detail, isometric 40° view, no text. A small chubby riverside ice cream parlor: cookie plank base on short wafer stilts, sky blue (#BDE7FF) fondant walls with pistachio (#C8E6A0) trim, a giant rounded ice cream cone with scoops as the roof, scalloped awning in white-pink (#FFE9F2) and sky blue, large simple service window with warm glow, slightly squashed playful proportions, blank sign board with no text, short soft purple-brown contact shadow to bottom-right, isolated on a plain flat solid neutral grey background.
```

- **Obligatorio:** techo con forma de cono de helado y pilotes de barquillo, por la orilla del río.
- **Prohibido:** agua o caramelo líquido dentro del asset (el río va en el fondo); helado derretido con aspecto sucio.
- **Observaciones:** la silueta del cono tiene que leerse sola, a 48 px.

---

## 12. Observaciones de integración

### Dónde va cada archivo

| Archivo | Carpeta | Lo carga |
|---|---|---|
| `fondo.png`, `preview.png` | `assets/maps/mapa_dulces/` | `MapDefinition` (`lib/services/map/map_catalog.dart`) |
| `textura_camino.png`, `flecha_bifurcacion.png`, `marca_*.png`, `diamante.png`, `trampa.png` | `assets/themes/dulces/` | tema `candy` (`ThemeAsset`, en `lib/services/map/map_theme.dart`) |
| `plataforma_0X.png`, `tienda_plaza.png`, `chocolateria.png`, `heladeria_rio.png` | por definir (ver abajo) | tilesets de `mapa.tmj` |

### Plataformas y tiendas: hay que actualizar Tiled

- `mapa.tmj` todavía referencia el arte clásico: `../../images/mapa/piezas/plataforma_0X.png` y `tienda.png`.
- **No sobrescribas esos archivos.** `mapa_01` los usa.
- Opción recomendada:
  1. Guarda las piezas de Mundo Dulce en una carpeta propia, por ejemplo `assets/images/mapa/dulces/`.
  2. Regístrala en `pubspec.yaml`.
  3. Crea en Tiled un tileset `casillas_dulces` con las cuatro plataformas y otro `objetos_dulces` con las tres tiendas, y reasigna cada casilla.
- **La propiedad `casilla` de cada plataforma en Tiled no puede cambiar**, porque es la que une el dibujo con el tablero lógico.

### Temas y respaldo

- Un tema solo necesita los dibujos que cambian. Lo que falte se toma del clásico y la app lo avisa en el log.
- `diamante.png` y `trampa.png` sin dibujo usan un ícono.
- `flecha_bifurcacion.png` sin dibujo usa la flecha clásica morada, que en este tema se confunde con la casilla especial. **Es una pieza obligatoria para el lanzamiento.**

### Tamaños con los que se dibujan

| Pieza | Tamaño en pantalla | Fuente |
|---|---|---|
| Marca de casilla | `MapScenery.markSize` | `lib/widgets/map/map_scenery.dart` |
| Marca de bifurcación | 1,3 × la marca | `MapScenery.forkMarkSize` |
| Flecha | dentro de un círculo, con 10% de relleno, rotada | `_arrow`, en `lib/widgets/map/board_map_view.dart` |
| Diamante en el indicador | dentro de un círculo, con 24% de relleno | `_DiamondIndicator`, en `board_map_view.dart` |
| Fondo | al doble (1440 × 3200 → mundo de 2880 × 6400) | `docs/arte_imagenes.md` |

### Excepción aprobada a `docs/arte_imagenes.md`: contorno chocolate

**Decisión aprobada:** Mundo Dulce es una excepción a las reglas de contorno de `docs/arte_imagenes.md`.

| Pieza | Regla general (`arte_imagenes.md`) | Mundo Dulce |
|---|---|---|
| Marcas de casilla, incluida `marca_bifurcacion.png` | sin contorno | **contorno chocolate `#3B2218`** |
| `flecha_bifurcacion.png` | contorno negro | **contorno chocolate `#3B2218`** |
| `diamante.png` | sin contorno | **contorno chocolate `#3B2218`** |
| `trampa.png` | — | **sin contorno (exención aprobada)**: ver la sección 8 |
| Plataformas, tiendas, textura del camino y fondo | sin contorno | sin contorno (igual que la regla general) |

- **Por qué:** el contorno garantiza que estas piezas se lean sobre el fondo rosado. En especial, separa la marca negativa (`#E57373`) del suelo `#F9D6E3`.
- **Grosor:** uniforme, unos 2 px a 48 px de tamaño y unos 5 px en un lienzo de 128. Nunca negro puro.
- La excepción también está anotada en `docs/arte_imagenes.md`. Si se cambia, se cambia en los dos documentos.

### Pendientes registrados

- **Revisar espaciado de bifurcaciones al integrar el TMJ definitivo.** En la prueba de la casilla 4, con el `.tmj` provisional y el zoom normal (2000 px de mundo visibles), las casillas 5 y 32 están a 364 px de la 4. Las plataformas, de 384 px, se tocan, y las flechas (a 88 px en pantalla del centro) caen encima de esas casillas. No bloquea el arte. Depende del espaciado del `.tmj` y de `_arrowDistance` (`lib/widgets/map/board_map_view.dart`).

### Antes de publicar el mapa

- [ ] Todos los PNG en su carpeta, con el tamaño exacto y sin pasar de 4096 px.
- [ ] `mapa.tmj` apunta a las piezas nuevas y se ve bien en Tiled.
- [ ] `preview.png` exportada con el arte final.
- [ ] Ninguna advertencia de "dibujo faltante" del tema `dulces` en el log.
- [ ] Prueba en un teléfono real de 360 px de ancho: se leen fichas, marcas, flechas y diamante.
- [ ] Después de todo esto, `selectable: true` en `MapCatalog.mapaDulces` y el interruptor remoto (ver `docs/activacion_mapas.md`).

---

## 13. Checklist de aprobación

Para cada asset:

- [ ] ¿Se lee la silueta en negro a 24–48 px?
- [ ] ¿La luz viene de arriba a la izquierda y la sombra cae abajo a la derecha? (La flecha y la textura van sin sombra proyectada.)
- [ ] ¿La sombra es violácea o chocolate, no gris?
- [ ] ¿El contorno es chocolate `#3B2218` con el grosor estándar? (Solo los íconos.)
- [ ] ¿Usa como máximo dos materiales protagonistas?
- [ ] ¿Evita los colores reservados del juego (salvo la marca que los usa)?
- [ ] ¿Respeta el dominante de su zona?
- [ ] ¿No tapa casillas, camino ni fichas?
- [ ] ¿Sigue viéndose bien en una pantalla de 360 px?
- [ ] ¿El recorte del fondo está limpio, sin halo gris?
- [ ] ¿Tiene el tamaño final exacto de este documento?
