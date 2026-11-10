import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/release_logging.dart';

/// Lo que [body] escribe en la consola.
List<String> _printed(void Function() body) {
  final lines = <String>[];
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  late DebugPrintCallback original;

  setUp(() => original = debugPrint);
  tearDown(() => debugPrint = original);

  group('silenceDebugLogsInRelease (H-09)', () {
    test('en release no llega nada a la consola', () {
      silenceDebugLogsInRelease(isRelease: true);

      final lines = _printed(
        () => debugPrint('Inicio de sesión: error de Firestore permission-denied'),
      );

      expect(lines, isEmpty);
    });

    test('en depuración se siguen viendo los mensajes', () {
      silenceDebugLogsInRelease(isRelease: false);

      final lines = _printed(() => debugPrint('mensaje de prueba'));

      expect(lines, contains('mensaje de prueba'));
    });
  });
}
