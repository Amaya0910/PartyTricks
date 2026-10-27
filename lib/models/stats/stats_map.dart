/// Lectura segura de los mapas que llegan de Firestore: los campos que no
/// existen valen 0 o un mapa vacío, y los números pueden llegar como double.
class StatsMap {
  const StatsMap._();

  static int readInt(Map<String, dynamic> map, String key) {
    return (map[key] as num?)?.toInt() ?? 0;
  }

  static Map<String, dynamic> readMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries) entry.key as String: entry.value,
    };
  }

  /// Mapa de nombre → número (por ejemplo, cofres abiertos por tipo).
  static Map<String, int> readIntMap(Map<String, dynamic> map, String key) {
    return {
      for (final entry in readMap(map, key).entries)
        entry.key: (entry.value as num?)?.toInt() ?? 0,
    };
  }
}
