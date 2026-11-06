# Arte de Party Tricks: lista de imágenes

> Responsable del arte: **Isabella Amaya**. Programa de dibujo: Krita.
> Última actualización: 6 de noviembre de 2026.
> Marca cada imagen con [x] cuando esté exportada y copiada en su carpeta.

## 1. Reglas para todas las imágenes

- **Un solo tamaño por imagen.** Dibuja en grande y exporta al tamaño de la tabla. No hacen falta carpetas `2.0x/` ni `3.0x/`; el código reduce la imagen y controla la memoria (`cacheWidth`). Si en un celular viejo va lento, se baja a 2x.
- **Formato:** PNG para todo. Los fondos grandes pueden pasar a WebP más adelante si la app pesa demasiado, sin redibujarlos.
- **Lienzo en Krita:** 72 ppp, RGB, 8 bits. Los ppp no importan en pantalla, solo los píxeles.
- **Estilo:**
  - **Sin contorno** en el escenario del mapa: plataformas, marcas, tienda, puentes, decoraciones, textura del camino y fondos.
  - **Con contorno negro** (mínimo 2 px en el tamaño exportado): personaje, cosméticos, flecha de bifurcación y marcas que lo necesiten. Moneda, diamante y dados van sin contorno.
  - Colores planos, con máximo 3 tonos por objeto: base, claro y oscuro.
  - **Luz desde arriba a la izquierda:** los brillos van arriba a la izquierda y las sombras abajo a la derecha, en todas las piezas.
  - Reutilizamos los colores que ya tenemos: el verde del pasto, el café de la tierra, la piel, el azul del diamante y el dorado de la moneda. Si se agrega uno nuevo, se anota, porque luego se pasa a `AppColors`.
- **Nombres:** en minúsculas, sin tildes ni espacios y con guion bajo. Las variantes se numeran con dos cifras, por ejemplo `plataforma_01.png`.
- **Ancla:** es el punto que el código usa para colocar la imagen. En Krita pon guías en ese punto.
- **Volteo:** no dibujes versiones al revés; el código puede voltear las imágenes. **Excepción:** las piezas con brillos o sombras de un solo lado (plataformas y tienda) **no se voltean**, porque la luz cambiaría de lado.
- **Carpetas:** cada carpeta nueva se agrega a `pubspec.yaml` en `flutter: assets:`, porque Flutter no lee subcarpetas solo.

## 2. Estructura de carpetas

```
assets/
├── images/
│   ├── Fondo_Principal.png        (rehacer, ver sección 3)
│   ├── Fondo_Carga.png            (reexportar, ver sección 3)
│   ├── logo_arranque.png
│   ├── cofres/                    los 3 cofres
│   ├── juego/                     moneda, diamante y dados
│   ├── mapa/
│   │   ├── piezas/                plataformas, marcas, tienda, flecha, puentes y textura del camino
│   │   └── decoraciones/          flores, rocas, arbustos y árboles
│   ├── personaje/                 capas del cuerpo: linea_<parte> y relleno_<parte> (sección 7)
│   │   ├── ojos/                  11 ojos (sección 8)
│   │   └── bocas/                 10 bocas (sección 8)
│   ├── cosmeticos/                (pendiente) camisa/  pantalon/  zapatos/  cabello/  nariz/
│   └── iconos/                    barra de navegación y marcador del jugador
├── maps/
│   └── mapa_01/                   mapa.json, fondo.png y minimapa.png (una carpeta por mapa)
└── icon/                          ícono de la app
```

- `assets/images/` guarda lo que **se reutiliza** en todos los mapas (plataformas, puentes, decoraciones).
- `assets/maps/<mapa>/` guarda lo que es **de un solo mapa** (su fondo, su minimapa y su `mapa.json`). Para agregar un mapa nuevo se copia una carpeta y se cambian esos tres archivos.

## 3. Fondos

| Hecho | Archivo | Carpeta | Exportar a (px) | Formato | Notas |
|---|---|---|---|---|---|
| [ ] | `Fondo_Principal.png` | `assets/images/` | 1080 × 2346 | PNG | El actual (440 × 956) se ve borroso en celulares de 1080 px. Mejor **redibujarlo**; si no, reescalarlo y repasar los bordes |
| [ ] | `Fondo_Carga.png` | `assets/images/` | 1440 × 2560 | PNG | Mismo dibujo. Pon el logo y los textos en el **80 % central**, porque en celulares altos se recorta de los lados |
| [ ] | `fondo.png` | `assets/maps/mapa_01/` | 1440 × 2160 | PNG | El mundo del mapa mide 2880 × 4320 y el código muestra el fondo al doble. Formas planas y suaves. Usa un verde **claramente distinto** al de las plataformas (más claro, más oscuro o más apagado) para que las casillas no se pierdan. Por ahora puede ser verde liso |

**Cómo pintar el fondo del mapa** (cuando el mapa ya esté armado en Tiled):

1. En Tiled, exporta el mapa armado con **Archivo → Exportar como imagen**.
2. En Krita, importa esa imagen como capa, escálala a 1440 × 2160 (la mitad exacta), bájale la opacidad al 30 % y ponla encima de todo como guía.
3. En capas separadas debajo, pinta el río o el agua **por debajo de cada puente** y lo demás que quieras (pasto más oscuro, orillas, bosque en los bordes).
4. Deja sin detalles fuertes la zona bajo cada plataforma, porque se asoma por los bordes.
5. Oculta la guía y exporta.

Todo lo que se ve en Tiled está al doble: una casilla en (1000, 3200) en Tiled queda en (500, 1600) en Krita.

## 4. Mapa: piezas reutilizables

Carpeta: `assets/images/mapa/piezas/`

- **Vista ¾**, como en los Zelda y Pokémon clásicos: se ve la cara de arriba de cada pieza y un poco de su frente.
- Las piezas de más abajo en la pantalla tapan a las de arriba.
- **Una sola plataforma sirve para todos los tipos de casilla.** El tipo se muestra con la marca pintada encima, con la moneda (positiva) o con la tienda detrás.

### Plataformas (casillas)

| Hecho | Archivo | Lienzo (px) | Ancla | Notas |
|---|---|---|---|---|
| [x] | `plataforma_01.png` | 384 × 320 | Centro del pasto (192, 160) | Redonda con bultos |
| [x] | `plataforma_02.png` | 384 × 320 | Centro del pasto (192, 160) | Alargada |
| [x] | `plataforma_03.png` | 384 × 320 | Centro del pasto (192, 160) | Dos lóbulos |
| [x] | `plataforma_04.png` | 384 × 320 | Centro del pasto (192, 160) | Irregular, con un bulto arriba |

Cómo es una plataforma:

- **Superficie de pasto** de unos 330 × 200 px, con silueta orgánica. Su centro va en el ancla, que es donde se paran los pies del personaje.
- **Borde de tierra** de unos 40 px **solo por el frente**, siguiendo la curva de abajo del pasto como una sonrisa y adelgazándose hacia los lados. Debajo de la tierra, transparente.
- **Franja oscura** justo debajo del pasto y **lado oscuro de la tierra a la derecha**, igual en las cuatro.
- **No se voltean.** Con 4 siluetas distintas el camino no se ve repetido.
- **Plantilla en Krita:** lienzo de 384 × 320 con guías en x = 192 e y = 160. Las 4 plataformas en `plataformas.kra`, un grupo por plataforma.

### Marcas de casilla

Van **planas, como pintadas sobre el pasto**, para que el personaje se pare encima sin taparlas.

| Hecho | Archivo | Lienzo (px) | Ancla | Notas |
|---|---|---|---|---|
| [ ] | `marca_inicio.png` | 192 × 192 | Centro (96, 96) | Círculo dorado con "Inicio" |
| [ ] | `marca_negativa.png` | 192 × 192 | Centro (96, 96) | X de lodo |
| [ ] | `marca_especial.png` | 192 × 192 | Centro (96, 96) | Signo de interrogación morado con destellos |

Cómo hacerlas:

1. Dibuja el símbolo **de frente**, centrado, llenando un círculo de unos 170 px.
2. Achátalo con la herramienta de transformación: **alto al 60 %**, ancho al 100 %. Queda de unos 170 × 100 px, en la misma perspectiva del pasto.
3. Déjalo centrado en el lienzo, en (96, 96).
4. Usa colores que contrasten con el verde del pasto.

### Tienda

| Hecho | Archivo | Lienzo (px) | Ancla | Notas |
|---|---|---|---|---|
| [ ] | `tienda.png` | 448 × 448 | Centro inferior (224, 448) | Edificio parado **detrás** de su casilla. La plataforma tapa su base unos 40 a 60 px. No se voltea |

- La tienda **no va dentro de la casilla**: se coloca en Tiled junto a ella (detrás, un poco a la izquierda o a la derecha, según quede el camino).
- Debe ser más alta que el personaje en el mapa (unos 180 × 270 px).
- La base termina recta abajo, sin pasto propio.
- Para probar proporciones, pon `plataforma_01.png` en una capa temporal delante y abajo, y ocúltala al exportar.

### Otras piezas

| Hecho | Archivo | Lienzo (px) | Ancla | Notas |
|---|---|---|---|---|
| [ ] | `flecha_bifurcacion.png` | 128 × 128 | Centro | Apunta a la **derecha**. El código la gira hacia cada camino |
| [ ] | `puente_horizontal.png` | 448 × 192 | Centro | Solo decorativo |
| [ ] | `puente_vertical.png` | 192 × 448 | Centro | Se dibuja aparte porque girarlo deforma la perspectiva |
| [ ] | `puente_diagonal.png` | 384 × 384 | Centro | Sirve para las dos diagonales con volteo, así que su luz debe verse bien de ambos lados |
| [ ] | `textura_camino.png` | 256 × 256 | — | Tierra que se repite sin cortes en los 4 lados. Usa el café de la tierra y un tono más oscuro para piedritas y grietas, **sin contorno**. El código traza la forma del caminito entre casillas y la rellena con esta textura |

- **Casilla positiva:** no tiene marca propia. Lleva encima la **moneda** (sección 6), y el código hace su animación (crece, sube y desaparece solo para ti).
- **Ancho del caminito:** cerca de la mitad del ancho de una plataforma. Sus extremos quedan tapados por las plataformas.

## 5. Mapa: decoraciones y minimapa

Carpeta: `assets/images/mapa/decoraciones/`. Todas con el **ancla en el centro inferior**, que es donde tocan el suelo. Sin contorno. Si tienen brillo de un solo lado, avísalo para no voltearlas.

| Hecho | Archivo | Lienzo (px) |
|---|---|---|
| [ ] | `deco_flor_01.png` a `deco_flor_03.png` (3) | 128 × 128 |
| [ ] | `deco_roca_01.png` a `deco_roca_03.png` (3) | 160 × 160 |
| [ ] | `deco_arbusto_01.png` y `deco_arbusto_02.png` (2) | 192 × 192 |
| [ ] | `deco_arbol_01.png` a `deco_arbol_03.png` (3) | 256 × 384 |

| Hecho | Archivo | Carpeta | Tamaño (px) | Formato | Notas |
|---|---|---|---|---|---|
| [ ] | `minimapa.png` | `assets/maps/mapa_01/` | 512 × 512 | PNG | Se saca de la imagen exportada de Tiled con el fondo puesto, reducida. No se dibuja aparte |
| [ ] | `marcador_jugador.png` | `assets/images/iconos/` | 96 × 96 | PNG | Marco circular para la foto de cada jugador en el minimapa |
| [ ] | `mapa.json` | `assets/maps/mapa_01/` | — | JSON | Posición de casillas, tienda, puentes y decoraciones. Se arma en **Tiled** (gratis) y un script lo convierte |

El mapa tiene 42 casillas:
- un camino principal cíclico, de la 0 a la 31;
- 2 desvíos: 1 → 32 a 36 → 8, y 13 → 37 a 41 → 23;
- tiendas en las casillas 17 y 36.  

Los caminos alternos miden lo mismo que el principal: dibújalos como ruta paralela (desvío o isla), no como atajo recto.

## 6. Elementos del juego

| Hecho | Archivo | Carpeta | Exportar a (px) | Notas |
|---|---|---|---|---|
| [x] | `Cofre_Basico.png`, `Cofre_Party.png`, `Cofre_Diamante.png` | `assets/images/cofres/` | 512 × 512 | Ya existen a 1080. Recorta el margen vacío y reduce |
| [x] | `moneda.png` | `assets/images/juego/` | 256 × 256 | Moneda dorada con el símbolo de pesos |
| [x] | `diamante.png` | `assets/images/juego/` | 384 × 384 | Diamante azul |
| [x] | `dado_1.png` a `dado_6.png` | `assets/images/juego/` | 192 × 192 cada uno | Cara 1 con un punto, 2 a 5 en números romanos y 6 con un diamante |

## 7. Personaje

Carpeta: `assets/images/personaje/`

- **Lienzo:** todas las capas se dibujan y se exportan a **512 × 768**, el mismo lienzo para el cuerpo, los ojos y las bocas. Así cada capa queda en su lugar sin ajustes; el código la reduce al tamaño que necesite.
- **Capas:** el cuerpo tiene 8 partes (cuerpo, pierna izquierda y derecha, brazo izquierdo y derecho, mano izquierda y derecha, cabeza). Cada parte tiene dos PNG: `relleno_<parte>.png` y `linea_<parte>.png`.
  - **Relleno:** va en **blanco**. El código lo tiñe con el tono de piel elegido (el negro del dibujo no se ve afectado).
  - **Línea:** el contorno negro, que no se tiñe. Va encima del relleno.
- **Animación:** la hace el código, no hay hojas de frames. Cada parte gira o se mueve alrededor de su punto de giro (en reposo: respiración, y la cabeza y los brazos suben y se balancean un poco). Por eso ya no se dibujan `personaje_caminar`, `personaje_reposo`, `personaje_celebrar` ni `personaje_negativa`; si hacen falta otras animaciones, se programan como nuevos movimientos de las mismas capas.
- **Proporción:** la de tu `Bodysheet.kra`: cabeza enorme (casi la mitad de la altura), nariz mínima.
- **Tonos de piel:** 40 en `AppColors.skinTones`: 20 realistas, de claro a oscuro, y 20 fantasiosos (negro, blanco, azul, etc.). No hay que dibujar nada para ellos.
- **Foto de perfil:** no es una imagen aparte. El código recorta la cabeza (relleno, línea, ojos y boca) en un cuadrado y la pone sobre un color de fondo que elige el jugador.

| Hecho | Archivos | Cantidad |
|---|---|---|
| [x] | `relleno_<parte>.png` y `linea_<parte>.png` | 16 (8 partes × 2) |

## 8. Cosméticos

### 8.1 Ojos y bocas (hechos)

Carpetas: `assets/images/personaje/ojos/` y `assets/images/personaje/bocas/`. Son capas del mismo lienzo de 512 × 768 y se dibujan encima de la cabeza (se mueven con ella).

| Hecho | Cosmético | Archivos |
|---|---|---|
| [x] | 11 ojos | `ojo_<n>.png` (1, 3, 6, 7, 8, 9 y 10) o dos capas `ojo_<n>_linea.png` y `ojo_<n>_relleno.png` (2, 4, 5 y 11) |
| [x] | 10 bocas | `boca_<n>.png` (2 a 7, 9 y 10) o dos capas `boca_<n>_linea.png` y `boca_<n>_relleno.png` (1 y 8) |

**Cómo se tiñen.** El color se aplica por código sobre lo que está en **blanco puro**; el negro y los demás colores del dibujo no cambian. Por eso, para que una parte pueda cambiar de color, se dibuja en blanco.

- **Ojos:** se tiñe la capa `_linea` (o el PNG único); el `_relleno` no se tiñe. Hay 20 colores y el primero deja el ojo como está dibujado.
- **Bocas:** se tiñe solo la capa que tiene el blanco (en la boca 8, la `_linea`; en las de un solo PNG, el PNG entero; en la 2 el blanco es el labial). Las bocas **1, 9 y 10 no se tiñen**: se ven siempre igual. Hay los mismos 20 colores, pero el primero es "sin color": lo blanco toma el **tono de piel** del personaje.
- **Capa de relleno:** va **debajo** de la línea. Si se dibuja con colores propios (rojo oscuro, lengua), esos colores no se tiñen.

La **rareza** de cada ojo y boca (que decide qué tan seguido salen en los cofres) y su precio no son arte: están en `eye_style.dart` y `mouth_style.dart` (ver D-29 a D-31 en `decisiones.md`).

### 8.2 Ropa, cabello y nariz (pendientes)

| Hecho | Archivo | Carpeta | Tamaño (px) |
|---|---|---|---|
| [ ] | `camisa_01`, `camisa_02` | `assets/images/cosmeticos/camisa/` | Lienzo de 512 × 768, igual que el personaje |
| [ ] | `pantalon_01`, `pantalon_02` | `assets/images/cosmeticos/pantalon/` | Igual |
| [ ] | `zapatos_01`, `zapatos_02` | `assets/images/cosmeticos/zapatos/` | Igual |
| [ ] | `cabello_01`, `cabello_02` | `assets/images/cosmeticos/cabello/` | Igual |
| [ ] | `nariz_01`, `nariz_02` | `assets/images/cosmeticos/nariz/` | Igual |

Las miniaturas ya no se dibujan: el Vestuario y la Tienda las sacan recortando el lienzo del personaje.

> **Pendiente antes de dibujar la ropa:** como el cuerpo se anima por partes, lo natural es dibujar la ropa **por partes del cuerpo** (por ejemplo, una capa de camisa para el cuerpo y otra para cada brazo), para que siga el movimiento. Hay que confirmarlo cuando se trabaje esa categoría.

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
  - `plataformas.kra` (las 4 plataformas);
  - marcas, tienda, flecha, puentes y textura del camino;
  - decoraciones;
  - personaje;
  - cosméticos;
  - interfaz;
  - uno por cada fondo.
- **Capas o grupos con el nombre final del archivo**, por ejemplo `plataforma_01`.
- **Exportar:** usa **Herramientas → Scripts → Exportar capas**, con "recortar a la capa" **desactivado**, para que cada pieza conserve su lienzo y encaje en el mismo ancla. Otra opción: oculta todo menos la pieza y usa **Archivo → Exportar** con **Guardar canal alfa** marcado.
- Antes de exportar, oculta la capa **Fondo** blanca y revisa en **Imagen → Propiedades** que el tamaño sea el de la tabla.

## 11. Resumen

| Grupo | Imágenes | Hechas |
|---|---|---|
| Fondos | 3 | 0 |
| Piezas del mapa (plataformas, marcas, tienda, flecha, puentes y textura) | 13 | 4 |
| Decoraciones | 11 | 0 |
| Minimapa y marcador | 2 | 0 |
| Cofres, moneda, diamante y dados | 11 (5 son solo reexportar) | 0 |
| Personaje (8 partes × línea y relleno) | 16 | 16 |
| Ojos y bocas | 11 + 10 | 21 |
| Ropa, cabello y nariz | 10 | 0 |
| Barra de navegación | 5 | 0 |
| Ícono y logo de arranque | 4 | 0 |

## 12. Orden recomendado

1. Plataformas (listas), marcas, tienda y textura del camino, para probar el mapa con tus dibujos.
2. Puentes, flecha y decoraciones.
3. Armar el mapa en Tiled y luego pintar su fondo y sacar el minimapa.
4. Reexportar cofres, moneda y diamante. Dibujar los dados.
5. Capas del personaje, ojos y bocas (hecho).
6. Fondos de la app (`Fondo_Principal` y `Fondo_Carga`).
7. Ropa, cabello y nariz, después de decidir cómo se dibuja la ropa por partes del cuerpo.
8. Barra de navegación, ícono de la app y logo de arranque.

## 13. Decisiones tomadas

- El mapa se dibuja con widgets de Flutter (`InteractiveViewer` + `Stack`), no con Flame. Flame queda para los minijuegos (`decisiones.md`, D-11). **Hay que confirmarlo con Brayan.**
- Cada mapa se describe en `assets/maps/<mapa>/mapa.json` y de ahí se construye el tablero. El anfitrión sortea el mapa de cada partida.
- El caminito entre casillas lo traza el código con tu `textura_camino`, sin contorno.
- El escenario del mapa va **sin contorno**; lo que se mueve o se toca va **con contorno negro**.
- La luz viene de arriba a la izquierda. Las plataformas y la tienda **no se voltean**.
- Las marcas de casilla van **planas sobre el pasto**; la **tienda** es un edificio **detrás** de su casilla.
- El mundo mide 2880 × 4320. Cada jugador ve solo su propio personaje; los demás aparecen en el minimapa.
- El personaje se arma con capas PNG por parte del cuerpo (línea y relleno) en un lienzo de 512 × 768 y se anima por código; no hay hojas de animación.
- Los ojos y las bocas son capas del mismo lienzo. Su color se aplica por código sobre lo que está en blanco puro; el tono de piel y los colores fantasiosos también son solo código.
- La foto de perfil es la cabeza del personaje sobre un color de fondo elegido en Ajustes (D-31), no una imagen subida.
- El fondo del mapa se pinta **después** de armar el mapa en Tiled, usando la imagen exportada como guía.
- **Para Brayan:** el código del mapa toca `board_layout.dart` (que pasa a leer el JSON) y `board_screen.dart`, que son de su rama. Hay que avisarle antes de empezar, en la rama `feature/mapa-dibujado`.

## 14. Preguntas abiertas

- [ ] ¿Qué es `AS.kra` (3072 × 3072, 79 capas)?
- [ ] ¿El **contorno blanco tipo sticker** va solo en portadas o también sobre el personaje en el mapa?
- [ ] ¿La ropa se dibuja por partes del cuerpo (como las capas del personaje) o en una sola capa?
- [ ] ¿Firebase Storage está disponible en el plan Spark? Si no, la foto de la cara se guarda reducida a 128 × 128 dentro de `users/{uid}` en Firestore.
