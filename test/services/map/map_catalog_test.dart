import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/models/app_protocol.dart';
import 'package:party_tricks/models/map/board_map.dart';
import 'package:party_tricks/services/game_engine/board_layout.dart';
import 'package:party_tricks/services/map/board_validator.dart';
import 'package:party_tricks/services/map/map_catalog.dart';
import 'package:party_tricks/services/map/tiled_map_parser.dart';

/// Lee el archivo de Tiled de [definition] tal como lo hace la app.
BoardMap _load(MapDefinition definition) {
  final json = jsonDecode(File(definition.tiledMap).readAsStringSync());
  return const TiledMapParser().parse(
    json as Map<String, dynamic>,
    mapDir: definition.assetDirectory,
    background: definition.background,
  );
}

void main() {
  test('mapa_01 es el mapa por defecto y se encuentra por su id', () {
    expect(MapCatalog.defaultMap, same(MapCatalog.mapa01));
    expect(MapCatalog.byId('mapa_01'), same(MapCatalog.mapa01));
    expect(MapCatalog.byId('no_existe'), isNull);
  });

  test('mapa_01 lo juega la 1.0.0', () {
    expect(MapCatalog.mapa01.minProtocol, ProtocolLevel.base);
  });

  test('mapa_01 conserva las rutas de siempre', () {
    const map = MapCatalog.mapa01;
    expect(map.tiledMap, 'assets/maps/mapa_01/mapa.tmj');
    expect(map.background, 'assets/maps/mapa_01/fondo.png');
  });

  test('el tablero de mapa_01 es el de siempre', () {
    final board = MapCatalog.mapa01.buildBoard();
    final original = buildDefaultBoard();

    expect(board.tiles.length, 42);
    for (final tile in board.tiles) {
      expect(tile.type, original.tile(tile.id).type);
      expect(tile.next, original.tile(tile.id).next);
    }
  });

  test('los ids de los mapas no se repiten', () {
    final ids = [for (final map in MapCatalog.all) map.id];
    expect(ids.toSet().length, ids.length);
  });

  for (final definition in MapCatalog.all) {
    group(definition.id, () {
      test('el tablero se puede jugar', () {
        final problems = validateBoard(definition.buildBoard());
        expect(problems, isEmpty, reason: problems.join('\n'));
      });

      test('el tablero y ${MapDefinition.tiledMapFile} tienen las mismas '
          'casillas', () {
        final problems = validateBoard(
          definition.buildBoard(),
          map: _load(definition),
        );
        expect(problems, isEmpty, reason: problems.join('\n'));
      });

      test('esta versión entiende su protocolo', () {
        expect(
          definition.minProtocol,
          inInclusiveRange(AppProtocol.legacy, AppProtocol.current),
        );
      });

      test('existen todas las imágenes que usa', () {
        final map = _load(definition);
        final assets = {
          map.background,
          for (final tile in map.tiles.values) tile.sprite.asset,
          for (final object in map.objects) object.asset,
        };
        for (final asset in assets) {
          expect(File(asset).existsSync(), isTrue, reason: 'Falta $asset');
        }
      });

      test('su carpeta está en los assets de pubspec.yaml', () {
        final pubspec = File('pubspec.yaml').readAsLinesSync();
        expect(
          pubspec.map((line) => line.trim()),
          contains('- ${definition.assetDirectory}/'),
        );
      });
    });
  }
}
