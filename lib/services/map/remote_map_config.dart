import 'package:party_tricks/models/map/map_id.dart';
import 'package:party_tricks/services/map/map_catalog.dart';

/// Qué mapas están encendidos desde Firebase (`config/maps` en Realtime
/// Database). Es el interruptor remoto: decide si un mapa listo
/// ([MapDefinition.selectable]) aparece de verdad para los jugadores.
///
/// En la base se ve así:
///
/// ```json
/// "config": { "maps": { "mapa_dulces": { "enabled": true } } }
/// ```
///
/// - Un mapa sin entrada, o con `enabled` distinto de `true`, está apagado.
/// - Las entradas de mapas que esta versión no conoce se ignoran: así se
///   puede encender un mapa antes de publicar la versión que lo trae.
/// - [defaultMapId] siempre está encendido: es el respaldo si Firebase no
///   responde, y la 1.0.0 lo juega sin preguntar.
class RemoteMapConfig {
  const RemoteMapConfig({this.enabledIds = const {}});

  /// Lee el valor de `config/maps`. Lo que no tenga la forma esperada se
  /// toma como apagado: la consola de Firebase no pasa por las reglas, así
  /// que puede llegar cualquier cosa.
  factory RemoteMapConfig.fromValue(Object? value) {
    if (value is! Map) return unavailable;
    return RemoteMapConfig(
      enabledIds: {
        for (final MapEntry(:key, :value) in value.entries)
          if (key is String && value is Map && value['enabled'] == true) key,
      },
    );
  }

  /// Sin configuración (Firebase caído, sin permiso o todavía cargando):
  /// solo [defaultMapId].
  static const unavailable = RemoteMapConfig();

  /// Los ids con `enabled: true`, conozca o no esta versión el mapa.
  final Set<String> enabledIds;

  /// Si el mapa [mapId] está encendido.
  bool isEnabled(String mapId) =>
      mapId == defaultMapId || enabledIds.contains(mapId);

  /// Si [map] se muestra: tiene que estar listo en el código **y**
  /// encendido en Firebase. En un build con [showHiddenMaps] basta lo
  /// segundo.
  bool isAvailable(MapDefinition map) =>
      (map.selectable || showHiddenMaps) && isEnabled(map.id);

  /// Los de [maps] que se muestran, en el mismo orden.
  List<MapDefinition> availableOf(List<MapDefinition> maps) => [
    for (final map in maps)
      if (isAvailable(map)) map,
  ];

  @override
  bool operator ==(Object other) =>
      other is RemoteMapConfig &&
      other.enabledIds.length == enabledIds.length &&
      other.enabledIds.containsAll(enabledIds);

  @override
  int get hashCode => Object.hashAllUnordered(enabledIds);

  @override
  String toString() => 'RemoteMapConfig($enabledIds)';
}
