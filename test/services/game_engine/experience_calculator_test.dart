import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game_engine/experience_calculator.dart';

void main() {
  const calc = ExperienceCalculator();

  test('coincide con la tabla del diseño (10 rondas)', () {
    expect(calc.xpForMatch(place: 1, players: 2, rounds: 10), 100);
    expect(calc.xpForMatch(place: 1, players: 4, rounds: 10), 130);
    expect(calc.xpForMatch(place: 2, players: 3, rounds: 10), 69);
    expect(calc.xpForMatch(place: 3, players: 3, rounds: 10), 35);
    expect(calc.xpForMatch(place: 3, players: 5, rounds: 10), 44);
    expect(calc.xpForMatch(place: 1, players: 6, rounds: 10), 160);
  });

  test('las rondas cambian la XP', () {
    expect(calc.xpForMatch(place: 1, players: 2, rounds: 5), 75);
    expect(calc.xpForMatch(place: 1, players: 6, rounds: 25), 280);
  });

  test('del 4º puesto en adelante y desconectados reciben 0', () {
    expect(calc.xpForMatch(place: 4, players: 6, rounds: 10), 0);
    expect(
      calc.xpForMatch(place: 1, players: 4, rounds: 10, disconnected: true),
      0,
    );
  });

  test('curva de niveles del diseño', () {
    expect(calc.xpToNextLevel(1), 75);
    expect(calc.xpToNextLevel(2), 121);
    expect(calc.xpToNextLevel(9), 725);
  });

  test('nivel según la XP acumulada', () {
    expect(calc.levelForXp(0), 1);
    expect(calc.levelForXp(74), 1);
    expect(calc.levelForXp(75), 2);
    expect(calc.levelForXp(196), 3);
    expect(calc.levelForXp(3227), 10);
  });
}
