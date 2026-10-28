import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/auth/account_rules.dart';

void main() {
  final now = DateTime(2026, 10, 27, 12);

  group('usernameWait', () {
    test('sin cambios anteriores puede cambiarlo', () {
      expect(AccountRules.usernameWait(null, now), isNull);
    });

    test('a los 30 días ya puede cambiarlo', () {
      final last = now.subtract(const Duration(days: 30));
      expect(AccountRules.usernameWait(last, now), isNull);
    });

    test('antes de los 30 días devuelve lo que falta', () {
      final last = now.subtract(const Duration(days: 20));
      expect(
        AccountRules.usernameWait(last, now),
        const Duration(days: 10),
      );
    });
  });

  group('usernameWaitMessage', () {
    test('menos de un día dice mañana', () {
      expect(
        AccountRules.usernameWaitMessage(const Duration(hours: 5)),
        'Podrás cambiar tu nombre mañana.',
      );
    });

    test('redondea los días hacia arriba', () {
      expect(
        AccountRules.usernameWaitMessage(const Duration(days: 2, hours: 1)),
        'Podrás cambiar tu nombre en 3 días.',
      );
    });
  });
}
