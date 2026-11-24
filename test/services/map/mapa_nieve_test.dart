import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/board_validator.dart';
import 'package:party_tricks/services/map/boards/mapa_nieve.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_theme.dart';
import 'package:party_tricks/services/rooms/room_protocol.dart';

/// Una vuelta desde la salida eligiendo [choices] en las bifurcaciones 14 y
/// 28 (0 = principal, 1 = atajo). Devuelve las casillas visitadas.
List<int> _lap(BoardLayout board, Map<int, int> choices) {
  final visited = <int>[];
  var id = BoardLayout.startId;
  do {
    final tile = board.tile(id);
    id = tile.next[tile.isFork ? choices[id]! : 0];
    visited.add(id);
  } while (id != BoardLayout.startId && visited.length < 200);
  return visited;
}

void main() {
  final board = buildSnowBoard();
  int count(TileType type) => board.tiles.where((t) => t.type == type).length;
  const routes = [
    {14: 0, 28: 0},
    {14: 1, 28: 0},
    {14: 0, 28: 1},
    {14: 1, 28: 1},
  ];

  test('se puede jugar', () {
    final problems = validateBoard(board);
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('42 casillas: 1 salida, 3 tiendas, 5 especiales y 8 negativas', () {
    expect(board.tiles, hasLength(42));
    expect(count(TileType.start), 1);
    expect(count(TileType.shop), 3);
    expect(count(TileType.special), 5);
    expect(count(TileType.negative), 8);
    expect(count(TileType.positive), 25);
  });

  test('atajos 14 → 36…39 → 22 y 28 → 40…41 → 32', () {
    expect(board.tile(14).next, [15, 36]);
    expect(board.tile(28).next, [29, 40]);
    expect(board.tile(39).next, [22]);
    expect(board.tile(41).next, [32]);
    expect(board.tile(35).next, [BoardLayout.startId]);
  });

  test('las vueltas miden 36, 33, 35 y 32 pasos', () {
    expect([for (final r in routes) _lap(board, r).length], [36, 33, 35, 32]);
  });

  test('nunca hay dos negativas seguidas en ninguna ruta', () {
    for (final route in routes) {
      final lap = [BoardLayout.startId, ..._lap(board, route)];
      for (var i = 1; i < lap.length; i++) {
        final both = [lap[i - 1], lap[i]].map((id) => board.tile(id).type);
        expect(
          both.every((t) => t == TileType.negative),
          isFalse,
          reason: '${lap[i - 1]} y ${lap[i]} en $route',
        );
      }
    }
  });

  test('las bifurcaciones y los reencuentros son positivos', () {
    for (final id in [14, 28, 22, 32]) {
      expect(board.tile(id).type, TileType.positive, reason: 'casilla $id');
    }
  });

  group('catálogo', () {
    const map = MapCatalog.mapaNieve;

    test('está registrado, listo, con su tema y su protocolo', () {
      expect(MapCatalog.byId('mapa_nieve'), same(map));
      expect(MapCatalog.defaultMap, same(MapCatalog.mapa01));
      expect(map.name, 'Reino Nevado');
      expect(map.selectable, isTrue);
      expect(map.theme, same(MapThemeCatalog.snow));
      expect(map.minProtocol, ProtocolLevel.snowMap);
      expect(AppProtocol.current, ProtocolLevel.snowMap);
    });

    test('sus salas piden snowMap y van a su propia lista pública', () {
      final required = requiredProtocolFor(
        RoomSettings(isPublic: true, mapId: 'mapa_nieve'),
      );
      expect(required, ProtocolLevel.snowMap);
      expect(publicLobbyFor(required), 'publicLobbyByProtocol/4');
    });
  });
}
