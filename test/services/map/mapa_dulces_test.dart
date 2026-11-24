import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/models/room.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/game_engine/game_action.dart';
import 'package:party_tricks/services/game_engine/game_engine.dart';
import 'package:party_tricks/services/game_engine/game_state.dart';
import 'package:party_tricks/services/map/board_summary.dart';
import 'package:party_tricks/services/map/board_validator.dart';
import 'package:party_tricks/services/map/boards/mapa_dulces.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/map_theme.dart';
import 'package:party_tricks/services/rooms/room_protocol.dart';

import '../game_engine/fake_random_source.dart';

/// Una vuelta desde la salida eligiendo [choices] en las bifurcaciones 4,
/// 11 y 37 (0 = principal, 1 = alterno). Devuelve las casillas visitadas,
/// sin la salida del principio.
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
  final board = buildCandyBoard();
  int count(TileType type) => board.tiles.where((t) => t.type == type).length;

  group('tablero', () {
    test('se puede jugar: ids seguidos, todo se alcanza y todo vuelve', () {
      final problems = validateBoard(board);
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('tiene 60 casillas con la distribución aprobada', () {
      expect(board.tiles, hasLength(60));
      expect(count(TileType.start), 1);
      expect(count(TileType.positive), 35);
      expect(count(TileType.negative), 14);
      expect(count(TileType.special), 7);
      expect(count(TileType.shop), 3);
    });

    test('tiendas en 3, 16 y 41', () {
      expect(
        [
          for (final t in board.tiles)
            if (t.type == TileType.shop) t.id,
        ],
        [3, 16, 41],
      );
    });

    test('bifurcaciones {4: 32, 11: 49, 37: 54}, con el principal primero', () {
      expect(
        {
          for (final t in board.tiles)
            if (t.isFork) t.id: t.next,
        },
        {
          4: [5, 32],
          11: [12, 49],
          37: [38, 54],
        },
      );
    });

    test('reencuentros {48: 27, 53: 20, 59: 45} y la vuelta en la 31', () {
      expect(board.tile(48).next, [27]);
      expect(board.tile(53).next, [20]);
      expect(board.tile(59).next, [45]);
      expect(board.tile(31).next, [BoardLayout.startId]);
      // Al 27 llegan los dos lóbulos.
      expect(
        [
          for (final t in board.tiles)
            if (t.next.contains(27)) t.id,
        ],
        [26, 48],
      );
    });

    test('se llega a todas las casillas desde la salida', () {
      final reached = <int>{BoardLayout.startId};
      final pending = [BoardLayout.startId];
      while (pending.isNotEmpty) {
        for (final next in board.tile(pending.removeLast()).next) {
          if (reached.add(next)) pending.add(next);
        }
      }
      expect(reached, hasLength(60));
    });

    test('las vueltas miden 32, 29, 27 y 26 pasos', () {
      expect(_lap(board, {4: 0, 11: 0, 37: 0}), hasLength(32));
      expect(_lap(board, {4: 0, 11: 1, 37: 0}), hasLength(29));
      expect(_lap(board, {4: 1, 11: 0, 37: 0}), hasLength(27));
      expect(_lap(board, {4: 1, 11: 0, 37: 1}), hasLength(26));
    });

    test('en cada bifurcación el camino 0 es el más largo', () {
      // Así las estadísticas de "atajos tomados" siguen teniendo sentido.
      expect(
        _lap(board, {4: 0, 11: 0, 37: 0}).length,
        greaterThan(_lap(board, {4: 1, 11: 0, 37: 0}).length),
      );
      expect(
        _lap(board, {4: 0, 11: 0, 37: 0}).length,
        greaterThan(_lap(board, {4: 0, 11: 1, 37: 0}).length),
      );
      expect(
        _lap(board, {4: 1, 11: 0, 37: 0}).length,
        greaterThan(_lap(board, {4: 1, 11: 0, 37: 1}).length),
      );
    });

    test('nunca hay dos negativas seguidas en ninguna ruta', () {
      for (final choices in const [
        {4: 0, 11: 0, 37: 0},
        {4: 0, 11: 1, 37: 0},
        {4: 1, 11: 0, 37: 0},
        {4: 1, 11: 0, 37: 1},
      ]) {
        final lap = _lap(board, choices);
        for (var i = 1; i < lap.length; i++) {
          final both =
              board.tile(lap[i - 1]).type == TileType.negative &&
              board.tile(lap[i]).type == TileType.negative;
          expect(both, isFalse, reason: '${lap[i - 1]} y ${lap[i]}');
        }
      }
    });

    test('las bifurcaciones y los reencuentros son positivos', () {
      for (final id in const [4, 11, 37, 20, 27, 45]) {
        expect(board.tile(id).type, TileType.positive, reason: 'casilla $id');
      }
      expect(board.tile(1).type, isNot(TileType.negative));
    });

    test('el resumen dice 60 casillas, 3 atajos, 3 tiendas y mediano', () {
      final summary = MapCatalog.mapaDulces.summary;
      expect(summary.tiles, 60);
      expect(summary.forks, 3);
      expect(summary.shops, 3);
      expect(summary.size, BoardSize.medium);
      // El primer mapa sigue siendo pequeño.
      expect(MapCatalog.mapa01.summary.size, BoardSize.small);
    });
  });

  group('con el motor', () {
    test('desde la salida, la bifurcación 4 llega en la primera tirada '
        '(pasando por la tienda 3)', () {
      final engine = GameEngine(
        board: board,
        mapId: 'mapa_dulces',
        random: FakeRandomSource(const []),
      );
      final state = GameState(
        players: const {'a': PlayerState(id: 'a', username: 'Ana')},
        turnOrder: const ['a'],
        totalRounds: 5,
        diamondTileId: 50,
        mapId: 'mapa_dulces',
      );
      // Un dado de 6 sale como 6. La 3 es una tienda: se detiene ahí de paso
      // con 3 pasos por dar.
      final rolled = GameEngine(
        board: board,
        mapId: 'mapa_dulces',
        random: FakeRandomSource(const [6]),
      ).apply(state, const RollDice('a'));
      expect(rolled.phase, GamePhase.shopping);
      expect(rolled.players['a']!.position, 3);
      expect(rolled.stepsLeft, 3);

      // Al seguir, llega a la bifurcación 4 con 2 pasos por dar.
      final atFork = engine.apply(rolled, const LeaveShop('a'));
      expect(atFork.phase, GamePhase.choosingBranch);
      expect(atFork.players['a']!.position, 4);
      expect(atFork.stepsLeft, 2);

      // Por el sur: 32 y 33 (negativa).
      final south = engine.apply(atFork, const ChooseBranch('a', 1));
      expect(south.players['a']!.position, 33);
      expect(south.players['a']!.shortcutsTaken, 1);
    });

    test('el diamante nunca aparece en la salida ni en las tiendas', () {
      final candidates = [
        for (final t in board.tiles)
          if (t.type != TileType.start && t.type != TileType.shop) t.id,
      ];
      expect(candidates, hasLength(56));
      for (var pick = 0; pick < candidates.length; pick++) {
        final game = GameEngine(
          board: board,
          mapId: 'mapa_dulces',
          random: FakeRandomSource([pick]),
        ).start(initialRolls: const [], totalRounds: 5);
        expect(game.diamondTileId, candidates[pick]);
        expect(game.mapId, 'mapa_dulces');
      }
    });
  });

  group('catálogo y protocolo', () {
    const map = MapCatalog.mapaDulces;

    test('está registrado; el mapa por defecto sigue siendo mapa_01', () {
      expect(MapCatalog.byId('mapa_dulces'), same(map));
      expect(MapCatalog.all.take(2), [MapCatalog.mapa01, map]);
      expect(MapCatalog.defaultMap, same(MapCatalog.mapa01));
      expect(map.name, 'Mundo Dulce');
      // Listo para el selector; falta encenderlo en Firebase.
      expect(map.selectable, isTrue);
      expect(map.tiledMap, 'assets/maps/mapa_dulces/mapa.tmj');
    });

    test('pide el nivel candyMap, que esta versión entiende', () {
      expect(ProtocolLevel.candyMap, greaterThan(ProtocolLevel.roomProtocol));
      expect(AppProtocol.current, greaterThanOrEqualTo(ProtocolLevel.candyMap));
      expect(map.minProtocol, ProtocolLevel.candyMap);
      expect(map.playableByAllVersions, isFalse);
      expect(MapCatalog.mapa01.playableByAllVersions, isTrue);
    });

    test('sus salas piden candyMap y van a su propia lista pública', () {
      final settings = RoomSettings(isPublic: true, mapId: 'mapa_dulces');
      final required = requiredProtocolFor(settings);

      expect(required, ProtocolLevel.candyMap);
      expect(publicLobbyFor(required), 'publicLobbyByProtocol/3');
      expect(playablePublicLobbies(), contains('publicLobbyByProtocol/3'));
      // Las de mapa_01 siguen en la lista que lee la 1.0.0.
      expect(
        publicLobbyFor(requiredProtocolFor(RoomSettings(isPublic: true))),
        'publicLobby',
      );
    });

    test('usa el tema dulces', () {
      expect(map.theme, same(MapThemeCatalog.candy));
      expect(map.theme.directory, 'assets/themes/dulces');
      expect(MapThemeCatalog.all, contains(MapThemeCatalog.candy));
    });

    test('el tema dulces usa su camino y toma lo demás del clásico', () {
      Set<String> filesIn(String dir) => {
        for (final f in Directory(dir).listSync().whereType<File>())
          '$dir/${f.uri.pathSegments.last}',
      };
      final resolved = resolveTheme(MapThemeCatalog.candy, {
        ...filesIn(MapThemeCatalog.classic.directory),
        ...filesIn(MapThemeCatalog.candy.directory),
      });

      expect(
        resolved[ThemeAsset.pathTexture],
        'assets/themes/dulces/textura_camino.png',
      );
      expect(
        resolved.markFor(TileType.negative),
        MapThemeCatalog.classic.pathOf(ThemeAsset.negativeMark),
      );
      expect(resolved.describeFallbacks(), contains('marca_negativa.png'));
    });
  });

  group('arte propio', () {
    // Mundo Dulce tiene que verse distinto del Mapa 1: sus plataformas y su
    // tienda son de dulce, no los arbustos y la cabaña de madera del Mapa 1.
    final tmj =
        jsonDecode(File('assets/maps/mapa_dulces/mapa.tmj').readAsStringSync())
            as Map<String, dynamic>;
    final images = <String>{
      for (final tileset in tmj['tilesets'] as List)
        for (final tile in (tileset as Map<String, dynamic>)['tiles'] as List)
          (tile as Map<String, dynamic>)['image'] as String,
    };

    test('sus plataformas y su tienda salen de su propia carpeta', () {
      expect(images, hasLength(5));
      for (final image in images) {
        expect(image, contains('/mapa/dulces/'), reason: image);
        expect(image, isNot(contains('/mapa/piezas/')), reason: image);
      }
    });

    test('todas las imágenes existen', () {
      for (final image in images) {
        final path = 'assets/maps/mapa_dulces/$image';
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('no se parecen a las del Mapa 1 (no son la misma imagen)', () {
      for (final name in [
        'plataforma_01',
        'plataforma_02',
        'plataforma_03',
        'plataforma_04',
      ]) {
        expect(
          File('assets/images/mapa/dulces/$name.png').readAsBytesSync(),
          isNot(File('assets/images/mapa/piezas/$name.png').readAsBytesSync()),
          reason: name,
        );
      }
      expect(
        File('assets/themes/dulces/textura_camino.png').readAsBytesSync(),
        isNot(
          File(
            'assets/images/mapa/piezas/textura_camino.png',
          ).readAsBytesSync(),
        ),
      );
    });
  });
}
