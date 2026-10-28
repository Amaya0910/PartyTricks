# Party Tricks — Progreso del desarrollo

> Registro de cada bloque de trabajo: qué se hizo y en qué estado quedó. Se agregan al final.

| Fecha | Bloque | Cambios | Estado |
| --- | --- | --- | --- |
| 2026-10-28 | Bloque 1 — Reglas de Realtime Database | `database.rules.json` (nuevo): reglas para `roomCodes`, `publicLobby` y `rooms/{id}` (`meta`, `players`, `game`, `actions`); todo lo demás cerrado. `firebase.json`: se agregan las secciones `database` y `firestore`. `docs/decisiones.md`: D-14 actualizada y D-24 nueva. Probado con el emulador (25 casos). Sin cambios en el código Dart. | 🟡 Listo para revisar; falta subir las reglas (`firebase deploy --only database`) y probar en el celular |
