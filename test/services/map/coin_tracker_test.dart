import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/map/coin_tracker.dart';

void main() {
  test('solo las casillas con moneda se pueden recoger', () {
    final coins = CoinTracker([2, 4]);

    expect(coins.isVisible(2), isTrue);
    expect(coins.isVisible(3), isFalse);
    expect(coins.collect(3), isFalse);
  });

  test('una moneda se recoge una sola vez', () {
    final coins = CoinTracker([2]);

    expect(coins.collect(2), isTrue);
    expect(coins.isVisible(2), isFalse);
    expect(coins.collect(2), isFalse);
  });

  test('las monedas vuelven al cambiar de ronda', () {
    final coins = CoinTracker([2])..onRound(1);
    coins.collect(2);

    coins.onRound(1);
    expect(coins.isVisible(2), isFalse);

    coins.onRound(2);
    expect(coins.isVisible(2), isTrue);
  });
}
