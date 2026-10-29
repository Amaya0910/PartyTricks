import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/board_walk.dart';

void main() {
  final walk = BoardWalk(buildDefaultBoard());

  test('camina casilla por casilla por el camino principal', () {
    expect(walk.between(2, 5), [3, 4, 5]);
  });

  test('si no se mueve no camina', () {
    expect(walk.between(7, 7), isEmpty);
  });

  test('da la vuelta por la salida', () {
    expect(walk.between(30, 1), [31, 0, 1]);
  });

  test('entra al desvío desde la bifurcación', () {
    expect(walk.between(1, 34), [32, 33, 34]);
  });

  test('sale del desvío y vuelve al camino principal', () {
    expect(walk.between(40, 24), [41, 23, 24]);
  });
}