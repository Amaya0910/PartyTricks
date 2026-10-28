import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/controllers/account_controller.dart';
import 'package:party_tricks/models/user_profile.dart';
import 'package:party_tricks/services/auth/auth_providers.dart';
import 'package:party_tricks/services/auth/auth_service.dart';
import 'package:party_tricks/services/stats/stats_providers.dart';

import '../services/auth/fake_account_service.dart';
import '../services/auth/fake_auth_service.dart';

const _password = 'Clave123!';

void main() {
  final now = DateTime(2026, 10, 27, 12);
  late FakeAccountService account;
  late FakeAuthService auth;

  setUp(() {
    account = FakeAccountService();
    auth = FakeAuthService();
  });

  Future<AccountController> controller({DateTime? usernameChangedAt}) async {
    final me = UserProfile(
      uid: 'me',
      email: 'tay@correo.com',
      username: 'Tay',
      friendCode: 'MYCDE2',
      usernameChangedAt: usernameChangedAt,
    );
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith((ref) => Stream.value(me)),
        accountServiceProvider.overrideWithValue(account),
        authServiceProvider.overrideWithValue(auth),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    // Riverpod 3 pausa los proveedores que nadie escucha.
    container.listen(userProfileProvider, (_, _) {});
    await container.read(userProfileProvider.future);
    return container.read(accountControllerProvider);
  }

  Matcher authError(String message) => throwsA(
    isA<AuthException>().having((e) => e.message, 'message', message),
  );

  group('changeUsername', () {
    test('guarda el nombre limpio y la fecha del cambio', () async {
      final c = await controller();

      await c.changeUsername('  Tay_2 ');

      expect(account.lastUsername, 'Tay_2');
      expect(account.lastUsernameAt, now);
    });

    test('rechaza el mismo nombre', () async {
      final c = await controller();

      await expectLater(
        c.changeUsername('Tay'),
        authError('Ese ya es tu nombre de usuario.'),
      );
      expect(account.lastUsername, isNull);
    });

    test('rechaza un nombre inválido sin llamar al servicio', () async {
      final c = await controller();

      await expectLater(c.changeUsername('a'), throwsA(isA<AuthException>()));
      expect(account.lastUsername, isNull);
    });

    test('pide esperar si lo cambió hace menos de 30 días', () async {
      final c = await controller(
        usernameChangedAt: now.subtract(const Duration(days: 25)),
      );

      await expectLater(
        c.changeUsername('Tay_2'),
        authError('Podrás cambiar tu nombre en 5 días.'),
      );
    });

    test('pasados 30 días deja cambiarlo', () async {
      final c = await controller(
        usernameChangedAt: now.subtract(const Duration(days: 31)),
      );

      await c.changeUsername('Tay_2');

      expect(account.lastUsername, 'Tay_2');
    });
  });

  test('regenerateFriendCode devuelve el código nuevo', () async {
    final c = await controller();

    expect(await c.regenerateFriendCode(), 'NEW234');
    expect(account.codeCalls, 1);
  });

  group('changePassword', () {
    test('con datos válidos llama al servicio', () async {
      final c = await controller();

      await c.changePassword(
        currentPassword: 'vieja',
        newPassword: _password,
        confirmPassword: _password,
      );

      expect(account.lastCurrentPassword, 'vieja');
      expect(account.lastNewPassword, _password);
    });

    test('rechaza si la confirmación no coincide', () async {
      final c = await controller();

      await expectLater(
        c.changePassword(
          currentPassword: 'vieja',
          newPassword: _password,
          confirmPassword: 'Otra123!',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(account.lastNewPassword, isNull);
    });

    test('rechaza si la nueva es igual a la actual', () async {
      final c = await controller();

      await expectLater(
        c.changePassword(
          currentPassword: _password,
          newPassword: _password,
          confirmPassword: _password,
        ),
        authError('La nueva contraseña debe ser diferente a la actual.'),
      );
    });

    test('muestra el mensaje del servicio', () async {
      account.nextError = const AuthException(
        'La contraseña actual no es correcta.',
      );
      final c = await controller();

      await expectLater(
        c.changePassword(
          currentPassword: 'mala',
          newPassword: _password,
          confirmPassword: _password,
        ),
        authError('La contraseña actual no es correcta.'),
      );
    });

    test('un error inesperado llega como mensaje general', () async {
      account.nextError = 'sin conexión';
      final c = await controller();

      await expectLater(
        c.changePassword(
          currentPassword: 'vieja',
          newPassword: _password,
          confirmPassword: _password,
        ),
        authError(
          'No se pudo completar. Revisa tu conexión e intenta de nuevo.',
        ),
      );
    });
  });

  group('changeEmail', () {
    test('envía el enlace al correo nuevo', () async {
      final c = await controller();

      await c.changeEmail(newEmail: 'nuevo@correo.com', currentPassword: 'x');

      expect(account.lastNewEmail, 'nuevo@correo.com');
    });

    test('rechaza el mismo correo sin importar mayúsculas', () async {
      final c = await controller();

      await expectLater(
        c.changeEmail(newEmail: 'TAY@correo.com', currentPassword: 'x'),
        authError('Ese ya es tu correo.'),
      );
    });

    test('rechaza un correo inválido', () async {
      final c = await controller();

      await expectLater(
        c.changeEmail(newEmail: 'no-es-correo', currentPassword: 'x'),
        throwsA(isA<AuthException>()),
      );
      expect(account.lastNewEmail, isNull);
    });
  });

  group('verificación del correo', () {
    test('sendEmailVerification llama al servicio', () async {
      final c = await controller();

      await c.sendEmailVerification();

      expect(auth.verificationEmails, 1);
    });

    test('checkEmailVerified devuelve lo que diga Firebase', () async {
      final c = await controller();
      expect(await c.checkEmailVerified(), isFalse);

      auth.emailVerified = true;
      expect(await c.checkEmailVerified(), isTrue);
    });
  });

  test('signOut cierra la sesión', () async {
    final c = await controller();

    await c.signOut();

    expect(auth.signOutCalls, 1);
  });
}
