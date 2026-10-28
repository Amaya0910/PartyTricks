import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/auth_user.dart';
import 'package:party_tricks/models/legal_document.dart';
import 'package:party_tricks/models/user_profile.dart';

void main() {
  group('AuthUser', () {
    test('con contraseña sin verificar ve el aviso', () {
      const user = AuthUser(
        uid: 'u',
        email: 'a@b.com',
        providers: {AuthUser.passwordProvider},
      );
      expect(user.hasPassword, isTrue);
      expect(user.needsEmailVerification, isTrue);
    });

    test('con el correo verificado no ve el aviso', () {
      const user = AuthUser(
        uid: 'u',
        email: 'a@b.com',
        emailVerified: true,
        providers: {AuthUser.passwordProvider},
      );
      expect(user.needsEmailVerification, isFalse);
    });

    test('con Google no ve el aviso', () {
      const user = AuthUser(
        uid: 'u',
        email: 'a@gmail.com',
        providers: {AuthUser.passwordProvider, AuthUser.googleProvider},
      );
      expect(user.hasGoogle, isTrue);
      expect(user.needsEmailVerification, isFalse);
    });
  });

  group('UserProfile.usernameChangedAt', () {
    test('se guarda en milisegundos y se lee igual', () {
      final changed = DateTime(2026, 10, 1, 9);
      final profile = UserProfile(
        uid: 'u',
        email: 'a@b.com',
        username: 'Tay',
        friendCode: 'ABC234',
        usernameChangedAt: changed,
      );

      final map = profile.toMap();
      expect(map['usernameChangedAt'], changed.millisecondsSinceEpoch);
      expect(UserProfile.fromMap('u', map).usernameChangedAt, changed);
    });

    test('si nunca lo cambió no se guarda', () {
      const profile = UserProfile(
        uid: 'u',
        email: 'a@b.com',
        username: 'Tay',
        friendCode: 'ABC234',
      );
      expect(profile.toMap().containsKey('usernameChangedAt'), isFalse);
      final read = UserProfile.fromMap('u', profile.toMap());
      expect(read.usernameChangedAt, isNull);
    });
  });

  test('los textos legales tienen secciones con contenido', () {
    for (final document in LegalDocument.values) {
      expect(document.title, isNotEmpty);
      expect(document.sections, isNotEmpty);
      for (final section in document.sections) {
        expect(section.heading, isNotEmpty);
        expect(section.paragraphs, isNotEmpty);
      }
    }
  });
}
