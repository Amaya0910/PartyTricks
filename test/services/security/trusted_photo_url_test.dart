import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/security/trusted_photo_url.dart';

void main() {
  group('TrustedPhotoUrl (H-03)', () {
    test('acepta fotos de cuentas de Google por HTTPS', () {
      expect(
        TrustedPhotoUrl.isTrusted(
          'https://lh3.googleusercontent.com/a/ACg8ocJ-foto_1=s96-c',
        ),
        isTrue,
      );
    });

    test('rechaza otros servidores, aunque se parezcan', () {
      for (final url in [
        'https://atacante.example/rastreo.png',
        'https://lh3.googleusercontent.com.atacante.example/a/foto',
        'https://lh3-googleusercontent.com/a/foto',
        'https://atacante.example/https://lh3.googleusercontent.com/a',
      ]) {
        expect(TrustedPhotoUrl.isTrusted(url), isFalse, reason: url);
      }
    });

    test('rechaza lo que no es HTTPS', () {
      for (final url in [
        'http://lh3.googleusercontent.com/a/foto',
        'ftp://lh3.googleusercontent.com/a/foto',
        'file:///data/data/com.partytricks.app/shared_prefs/x.xml',
        'data:image/png;base64,AAAA',
        'javascript:alert(1)',
      ]) {
        expect(TrustedPhotoUrl.isTrusted(url), isFalse, reason: url);
      }
    });

    test('rechaza puertos, usuario en la URL, ruta vacía y textos largos', () {
      for (final url in [
        'https://lh3.googleusercontent.com:8443/a/foto',
        'https://alguien@lh3.googleusercontent.com/a/foto',
        'https://lh3.googleusercontent.com/',
        '',
        'https://lh3.googleusercontent.com/${'a' * 2100}',
      ]) {
        expect(TrustedPhotoUrl.isTrusted(url), isFalse, reason: url);
      }
    });
  });
}
