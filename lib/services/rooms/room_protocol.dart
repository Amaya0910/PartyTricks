import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/map/map_catalog.dart';

/// Lo que usa una sala que no todas las versiones entienden. Hoy solo el
/// mapa; cuando haya minijuegos, ítems o acciones que pidan un protocolo
/// mayor, se agregan aquí y [requiredProtocolFor] los cuenta solo.
List<ProtocolFeature> featuresOf(RoomSettings settings) => [
  MapCatalog.require(settings.mapId),
];

/// El `requiredProtocol` de una sala nueva con [settings].
int requiredProtocolFor(RoomSettings settings) =>
    AppProtocol.requiredFor(featuresOf(settings));

/// Dónde se anuncia una sala pública según el protocolo que necesita.
///
/// Las de [AppProtocol.legacy] van en `publicLobby`, la lista que lee la
/// 1.0.0. Las demás van en `publicLobbyByProtocol/{n}`, que la 1.0.0 no
/// conoce: si las viera, al no poder entrar (las reglas no la dejan) se le
/// cortaría la búsqueda de sala. Cada sala está en una sola lista.
String publicLobbyFor(int requiredProtocol) =>
    requiredProtocol <= AppProtocol.legacy
    ? 'publicLobby'
    : 'publicLobbyByProtocol/$requiredProtocol';

/// Las listas públicas que esta versión puede jugar, de la más nueva a la
/// más vieja.
List<String> playablePublicLobbies() => [
  for (var p = AppProtocol.current; p >= AppProtocol.legacy; p--)
    publicLobbyFor(p),
];
