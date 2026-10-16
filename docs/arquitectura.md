# Party Tricks — Arquitectura (propuesta inicial)

> Proyecto de aula · Programación Móvil
> Documento para la primera presentación. Son ideas propuestas y básicas, que se afinarán durante el desarrollo.
> Complementa a `diseno_juego.md`.

---

## 1. Tecnologías

| Tema | Elección |
|---|---|
| App | Flutter |
| Backend | Firebase |
| Gestor de estado | Riverpod |
| Lógica de la partida | El celular del creador de la sala hace de "servidor" |

**Juegos:** se toma como referencia el Flutter Casual Games Toolkit. El tablero y los turnos son por turnos y se hacen con Flutter y Riverpod, sin motor. Flame se usa solo en los minijuegos de tiempo real que lo necesiten (ver `decisiones.md`, D-11).

---

## 2. Idea general

La app se divide en capas simples, cada una con una responsabilidad:

```
Pantallas  →  Controladores (Riverpod)  →  Servicios  →  Firebase
```

- **Pantallas:** muestran la información y reciben los toques del jugador.
- **Controladores:** contienen la lógica de cada pantalla.
- **Servicios:** se comunican con Firebase y aplican las reglas del juego.
- **Modelos:** representan los datos (jugador, sala, partida, etc.).

Estas son las cinco carpetas base de `lib/`: `controllers`, `models`, `screens`, `services` y `widgets`.

Los principios SOLID se aplican separando responsabilidades: las pantallas no hablan con Firebase directamente, y las reglas del juego viven aparte, en código que no depende de Firebase ni de la interfaz, por lo que se puede probar solo.

---

## 3. Firebase: qué se usa y para qué

| Servicio | Uso |
|---|---|
| Authentication | Registro e inicio de sesión con correo y contraseña (Firebase guarda la contraseña, no la base de datos del juego) |
| Cloud Firestore | Datos permanentes: perfiles, amigos, chat, catálogo de la tienda |
| Realtime Database | Datos de la partida en vivo: salas, turnos, posiciones y detección de desconexiones |
| Storage | Foto del rostro del personaje |

---

## 4. Qué se guarda de cada jugador

- Correo y nombre de usuario (único).
- Código de amistad (único).
- Experiencia acumulada; el nivel se calcula a partir de ella.
- Monedas y diamantes de la cuenta.
- Cosméticos desbloqueados y equipados (el rostro del personaje es la foto de perfil).
- Lista de amigos y chats.

---

## 5. Cómo funciona una partida en línea

1. **Sala:** el creador define jugadores, rondas y si es pública o privada. Se entra con un código o a una sala pública aleatoria.
2. **Lobby:** espera máxima de 1:30. Si hay 2 o más jugadores empieza; si no, se cierra la sala con un mensaje.
3. **Turnos:** el jugador envía una acción ("lanzar dado", "comprar ítem"). El celular del creador la valida, calcula el resultado (dado, movimiento, monedas, efectos) y lo guarda en Firebase. Los demás celulares ven el cambio al instante.
4. **Final:** se calculan los diamantes finales, el ganador y la experiencia, y cada jugador guarda su resultado en su cuenta.

Toda la partida se guarda en Firebase y no solo en el celular del creador. Así, si el creador se desconecta, otro jugador puede tomar ese rol y continuar.

---

## 6. Desconexiones

| Situación | Qué pasa |
|---|---|
| Se desconecta un jugador y quedan 2 o más | La partida sigue sin él; no recibe monedas, diamantes ni experiencia |
| Queda un solo jugador | Ve "Lo sentimos, no quedan jugadores :(" y el botón [Regresar a menú] |
| Se desconecta el creador de la sala | Otro jugador toma su rol y la partida continúa |

---

## 7. Gestor de estado: Riverpod

- Los datos en tiempo real (sala, partida, chat) llegan como flujos que las pantallas observan y se actualizan solas.
- Cada pantalla importante tiene un controlador con su lógica.
- Los servicios se entregan por interfaz, lo que permite reemplazarlos por versiones falsas en las pruebas.

---

## 8. Chat y reacciones

- **Chat:** solo entre amigos, en el menú principal; cada mensaje es un registro ordenado por fecha.
- **Reacciones (propuesto):** emojis rápidos que se muestran sobre el personaje durante la partida, con un límite de frecuencia.

---

## 9. Limitaciones conocidas

- Con el celular del creador como "servidor", un jugador con la app modificada podría hacer trampa. Para un proyecto de aula es aceptable; si el juego se publicara, el cálculo se movería a Cloud Functions de Firebase.
- Los jugadores pueden ser menores y se guardan fotos de rostros: la foto debe ser opcional y el chat debe permitir reportar y bloquear.

---

## 10. Pendientes

- [ ] Qué pasa si un jugador desconectado quiere volver a la partida.
- [ ] Tiempo máximo por turno, por si alguien se queda inactivo.
- [ ] Reglas de seguridad de Firebase.
- [ ] Moderación del chat.
- [x] Si los minijuegos necesitan un motor de animación: se decide por minijuego; Flame solo si hace falta (ver `decisiones.md`, D-11).
- [ ] Prueba corta de Flame con el minijuego más sencillo.