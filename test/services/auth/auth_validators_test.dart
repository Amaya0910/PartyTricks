import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/auth/auth_validators.dart';

void main() {
  group('email', () {
    test('acepta un correo válido', () {
      expect(AuthValidators.email('tay@correo.com'), isNull);
      expect(AuthValidators.email('  tay@correo.com  '), isNull);
    });

    test('rechaza vacío y formatos inválidos', () {
      expect(AuthValidators.email(null), isNotNull);
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('tay'), isNotNull);
      expect(AuthValidators.email('tay@correo'), isNotNull);
      expect(AuthValidators.email('tay @correo.com'), isNotNull);
    });
  });

  group('identifier (correo o nombre de usuario)', () {
    test('acepta un correo o un nombre de usuario', () {
      expect(AuthValidators.identifier('tay@correo.com'), isNull);
      expect(AuthValidators.identifier('Tay_01'), isNull);
      expect(AuthValidators.identifier('  tay_01  '), isNull);
    });

    test('rechaza vacío', () {
      expect(AuthValidators.identifier(null), isNotNull);
      expect(AuthValidators.identifier('   '), isNotNull);
    });

    test('si trae arroba, revisa el formato del correo', () {
      expect(AuthValidators.identifier('tay@correo'), isNotNull);
      expect(AuthValidators.identifier('tay@'), isNotNull);
    });
  });

  group('username', () {
    test('acepta letras, números y guion bajo', () {
      expect(AuthValidators.username('Tay_01'), isNull);
      expect(AuthValidators.username('abc'), isNull);
      expect(AuthValidators.username('a' * 16), isNull);
    });

    test('rechaza vacío, muy corto y muy largo', () {
      expect(AuthValidators.username(null), isNotNull);
      expect(AuthValidators.username(''), isNotNull);
      expect(AuthValidators.username('ab'), isNotNull);
      expect(AuthValidators.username('a' * 17), isNotNull);
    });

    test('rechaza espacios y símbolos', () {
      expect(AuthValidators.username('tay 01'), isNotNull);
      expect(AuthValidators.username('tay-01'), isNotNull);
      expect(AuthValidators.username('tay!'), isNotNull);
    });
  });

  group('newPassword', () {
    test('acepta una contraseña con todo lo pedido', () {
      expect(AuthValidators.newPassword('Clave123!'), isNull);
      expect(AuthValidators.newPassword('aB3\$aaaa'), isNull);
    });

    test('rechaza vacía y muy corta', () {
      expect(AuthValidators.newPassword(null), isNotNull);
      expect(AuthValidators.newPassword(''), isNotNull);
      expect(AuthValidators.newPassword('Ab1!'), isNotNull);
      expect(AuthValidators.newPassword('Abc123!'), isNotNull); // 7 caracteres
    });

    test('rechaza si falta la mayúscula', () {
      expect(
        AuthValidators.newPassword('clave123!'),
        'La contraseña debe incluir una mayúscula.',
      );
    });

    test('rechaza si falta la minúscula', () {
      expect(
        AuthValidators.newPassword('CLAVE123!'),
        'La contraseña debe incluir una minúscula.',
      );
    });

    test('rechaza si falta el número', () {
      expect(
        AuthValidators.newPassword('ClaveClave!'),
        'La contraseña debe incluir un número.',
      );
    });

    test('rechaza si falta el símbolo', () {
      expect(
        AuthValidators.newPassword('Clave12345'),
        'La contraseña debe incluir un símbolo (por ejemplo ! o #).',
      );
    });

    test('un espacio no cuenta como símbolo', () {
      expect(AuthValidators.newPassword('Clave 12345'), isNotNull);
    });
  });

  group('existingPassword y confirmPassword', () {
    test('existingPassword solo pide que no esté vacía', () {
      expect(AuthValidators.existingPassword(null), isNotNull);
      expect(AuthValidators.existingPassword(''), isNotNull);
      expect(AuthValidators.existingPassword('x'), isNull);
    });

    test('confirmPassword compara con la contraseña', () {
      expect(AuthValidators.confirmPassword('Clave123!', ''), isNotNull);
      expect(AuthValidators.confirmPassword('Clave123!', 'otra'), isNotNull);
      expect(AuthValidators.confirmPassword('Clave123!', 'Clave123!'), isNull);
    });
  });
}
