/// Id de la pareja de dos jugadores: los dos uid en orden alfabético, unidos
/// con `_`. Es el mismo sin importar quién lo calcule, así la amistad y el
/// chat entre dos jugadores siempre tienen un solo documento.
class PairId {
  const PairId._();

  static String of(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Los dos uid en orden alfabético.
  static List<String> members(String a, String b) => [a, b]..sort();
}
