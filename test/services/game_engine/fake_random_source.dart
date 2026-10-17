import 'package:party_tricks/services/game_engine/random_source.dart';

/// Azar controlado para las pruebas: devuelve los valores en orden.
class FakeRandomSource extends RandomSource {
  FakeRandomSource(List<int> values) : _values = List.of(values);

  final List<int> _values;

  @override
  int nextInt(int min, int max) {
    final value = _values.removeAt(0);
    if (value < min || value > max) {
      throw ArgumentError('$value no está entre $min y $max');
    }
    return value;
  }
}
