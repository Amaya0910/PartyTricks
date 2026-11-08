import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/game/game_providers.dart';
import 'package:party_tricks/services/game/game_service.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_codec.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/turn_order_resolver.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_providers.dart';

import '../game_engine/fake_random_source.dart';
import '../game_engine/test_board.dart';

const _rolls = [
  InitialRoll(playerId: 'a', username: 'Ana', value: 6),
  InitialRoll(playerId: 'b', username: 'Beto', value: 1),
];

GameEngine _engine(String mapId) => GameEngine(
  mapId: mapId,
  board: buildTestBoard(),
  random: FakeRandomSource([5, 2, 3]),
);

void main() {
  const codec = GameCodec();
  final roll = codec.encodeAction(const RollDice('a'));

  test('el motor arma la partida con su mapa', () {
    for (final mapId in ['mapa_01', 'mapa_02']) {
      final game = _engine(mapId).start(initialRolls: _rolls, totalRounds: 5);
      expect(game.mapId, mapId);
    }
  });

  test('el motor no juega partidas de otro mapa', () {
    final game = _engine('mapa_02').start(initialRolls: _rolls, totalRounds: 5);

    expect(
      () => _engine('mapa_01').apply(game, const RollDice('a')),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'La partida es del mapa mapa_02, no del mapa_01',
        ),
      ),
    );
    final stored = codec.encodeState(game);
    expect(hostApply(_engine('mapa_01'), stored, roll), isNull);
    expect(hostApply(_engine('mapa_02'), stored, roll), isNotNull);
  });

  test('una partida de antes de los mapas la juega el motor de mapa_01', () {
    final stored = codec.encodeState(
      _engine('mapa_01').start(initialRolls: _rolls, totalRounds: 5),
    )..remove('mapId');

    final next = hostApply(_engine('mapa_01'), stored, roll);

    expect(next, isNotNull);
    // Al guardarla de nuevo ya queda con su mapa.
    expect(next!['mapId'], 'mapa_01');
  });

  group('providers por mapa', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('mapa_01 usa su tablero y su motor', () {
      final engine = container.read(gameEngineProvider('mapa_01'));

      expect(engine.mapId, 'mapa_01');
      expect(engine.board.tiles.length, 42);
      expect(container.read(boardProvider('mapa_01')), same(engine.board));
      expect(
        container.read(mapDefinitionProvider('mapa_01')),
        same(MapCatalog.mapa01),
      );
    });

    test('un mapa que esta versión no tiene da UnknownMapException', () {
      // Riverpod lo entrega envuelto en ProviderException, una vez por cada
      // provider del que depende.
      Object unwrap(Object error) =>
          error is ProviderException ? unwrap(error.exception) : error;
      final unknown = throwsA(
        isA<ProviderException>().having(
          unwrap,
          'error original',
          isA<UnknownMapException>(),
        ),
      );
      expect(() => container.read(mapDefinitionProvider('mapa_99')), unknown);
      expect(() => container.read(gameEngineProvider('mapa_99')), unknown);
    });
  });

  test('MapCatalog.require encuentra mapa_01 y rechaza los demás', () {
    expect(MapCatalog.require('mapa_01'), same(MapCatalog.mapa01));
    expect(
      () => MapCatalog.require('mapa_99'),
      throwsA(
        isA<UnknownMapException>().having((e) => e.mapId, 'mapId', 'mapa_99'),
      ),
    );
  });
}
