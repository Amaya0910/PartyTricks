# Grabación del tráiler: checklist

Para grabar `mapa_01`, `mapa_dulces` y `mapa_nieve`. Proyecto de Firebase: `party-tricks` (el único que hay: es producción).

## 0. Una sola vez, antes del día de grabación

- [ ] Hacer commit del trabajo pendiente. `database.rules.json` tiene sin commit la regla que permite crear salas con mapas encendidos en `config/maps`.
- [ ] Desplegar **solo** las reglas de Realtime Database:

  ```
  firebase deploy --only database --project party-tricks
  ```

- [ ] En la consola de Firebase → Realtime Database → Datos, crear:

  ```json
  "config": {
    "maps": {
      "mapa_dulces": { "enabled": true, "note": "tráiler" },
      "mapa_nieve":  { "enabled": true, "note": "tráiler" }
    }
  }
  ```

  Es seguro en producción: los builds normales siguen sin mostrarlos, porque tienen `selectable: false`. Solo los ve el build con `SHOW_HIDDEN_MAPS`.

## 1. Build de tráiler

Conecta los teléfonos por USB y mira sus ids:

```
flutter devices
```

**Opción A, un teléfono a la vez** (con log para verificar):

```
flutter run -d <id> --profile --dart-define=SHOW_HIDDEN_MAPS=true
```

**Opción B, varios teléfonos** (para grabar):

```
flutter build apk --release --dart-define=SHOW_HIDDEN_MAPS=true
adb -s <id> install -r build/app/outputs/flutter-apk/app-release.apk
```

Repite el `adb install` en cada teléfono. **Todos** tienen que tener este build: el protocolo 4 bloquea a las versiones anteriores.

## 2. Verificar que cargan (con la opción A, antes de grabar)

- [ ] Crear sala → Mapa → aparecen **3 mapas**: Mapa 1, Mundo Dulce y Reino Nevado. Si faltan, revisa `config/maps` en Firebase (`enabled` tiene que ser `true` booleano, no texto).
- [ ] Crear una sala privada en cada mapa y entrar con un segundo teléfono.
- [ ] Al cargar cada mapa:
  - [ ] Se ve el fondo: rosa en Dulce, blanco y azul con pinos en Nevado.
  - [ ] Se ven el camino y todas las plataformas.
  - [ ] En el log de `flutter run` no aparecen errores de imagen faltante. Los avisos de "tomado del clásico" del tema sí son esperados.
- [ ] Llegar a una bifurcación en cada mapa: salen las flechas y responden al toque.
- [ ] Si "Crear sala" dice "Ese mapa ya no está disponible", las reglas no están desplegadas o falta el `enabled`.

## 3. Grabar

Prepara de 2 a 4 cuentas con sesión iniciada y avatares distintos. Usa sala privada, rondas cortas y la misma resolución en todos los teléfonos.

| Mapa | Tomas | Mensaje |
|---|---|---|
| **mapa_01** | selector → salida → primera tirada → **bifurcación 1** con flechas → caer en tienda (17 o 36) | "así se juega" |
| **mapa_dulces** | pasar del Mapa 1 a Mundo Dulce en el selector → **bifurcación 4** (Reino de Chocolate al norte o Río al sur) → vista de un lóbulo → caer en especial y en negativa | "elige tu mundo" |
| **mapa_nieve** | miniatura blanca en el selector → subida en zigzag (3–13) → **bifurcación 14**: cruzar el Puente de Hielo (36–39) y caer en negativa → iglú → Cueva de Hielo (28 → 40–41) | "arriésgate" |

- **Evita en Dulce:** el atajo de la Cascada (54–59, las plataformas se rozan) y los primeros planos de las tiendas (arte provisional con texto).
- **En los tres:** una toma limpia de la bifurcación con flechas y el indicador del diamante fuera de pantalla una vez.
- **Montaje:** la misma decisión de bifurcación en los tres, en cortes rápidos (verde, rosa, blanco).

## 4. Después de grabar

- [ ] Revisar los videos: que no haya cortes de red ni avisos de desconexión, y que las flechas y el diamante se vean.
- [ ] Apagar los mapas en Firebase: `config/maps/mapa_dulces/enabled = false` y `config/maps/mapa_nieve/enabled = false`, o borrar las entradas. Las partidas en curso terminan normalmente.
- [ ] Desinstalar el APK de tráiler de los teléfonos que no son tuyos, porque muestra mapas ocultos.
- [ ] No publicar ese APK: el flag es solo para builds internos.
