import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/app_protocol.dart';

class _Feature implements ProtocolFeature {
  const _Feature(this.minProtocol);

  @override
  final int minProtocol;
}

void main() {
  test('la 1.0.0 cuenta como el nivel base', () {
    expect(AppProtocol.legacy, ProtocolLevel.base);
    expect(AppProtocol.current, greaterThanOrEqualTo(AppProtocol.legacy));
  });

  test('sin nada especial, alcanza con el protocolo de la 1.0.0', () {
    expect(AppProtocol.requiredFor(const []), AppProtocol.legacy);
  });

  test('una partida necesita el mayor protocolo de lo que usa', () {
    expect(
      AppProtocol.requiredFor(const [_Feature(1), _Feature(4), _Feature(2)]),
      4,
    );
  });

  test('esta versión juega hasta su protocolo, no más', () {
    expect(AppProtocol.supports(AppProtocol.legacy), isTrue);
    expect(AppProtocol.supports(AppProtocol.current), isTrue);
    expect(AppProtocol.supports(AppProtocol.current + 1), isFalse);
  });
}
