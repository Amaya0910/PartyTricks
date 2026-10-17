import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/turn_order_resolver.dart';

void main() {
  const resolver = TurnOrderResolver();

  test('el número más alto juega primero', () {
    final orden = resolver.resolve(const [
      InitialRoll(playerId: 'a', username: 'Ana', value: 2),
      InitialRoll(playerId: 'b', username: 'Beto', value: 6),
      InitialRoll(playerId: 'c', username: 'Caro', value: 4),
    ]);
    expect(orden, ['b', 'c', 'a']);
  });

  test('en empate va de último el nombre más cercano a la Z', () {
    final orden = resolver.resolve(const [
      InitialRoll(playerId: 'z', username: 'Zoe', value: 5),
      InitialRoll(playerId: 'm', username: 'Mateo', value: 5),
      InitialRoll(playerId: 'a', username: 'Andres', value: 5),
    ]);
    expect(orden, ['a', 'm', 'z']);
  });

  test('el desempate no distingue mayúsculas', () {
    final orden = resolver.resolve(const [
      InitialRoll(playerId: '1', username: 'zeta', value: 3),
      InitialRoll(playerId: '2', username: 'Alfa', value: 3),
    ]);
    expect(orden, ['2', '1']);
  });
}
