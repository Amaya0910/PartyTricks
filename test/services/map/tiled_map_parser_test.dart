import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:party_tricks/services/map/tiled_map_parser.dart';

/// Un mapa de Tiled pequeño, con la forma que guarda el programa.
Map<String, dynamic> _tiledMap({
  List<Map<String, dynamic>>? tilesets,
  List<Map<String, dynamic>>? casillas,
  List<Map<String, dynamic>>? objetos,
}) {
  return {
    'width': 90,
    'height': 135,
    'tilewidth': 32,
    'tileheight': 32,
    'tilesets':
        tilesets ??
        [
          {
            'firstgid': 1,
            'name': 'casillas',
            'objectalignment': 'center',
            'tiles': [
              {
                'id': 0,
                'image': '../../images/mapa/piezas/plataforma_01.png',
                'imagewidth': 384,
                'imageheight': 320,
              },
            ],
          },
          {
            'firstgid': 2,
            'name': 'objetos',
            'objectalignment': 'bottom',
            'tiles': [
              {
                'id': 0,
                'image': '../../images/mapa/piezas/tienda.png',
                'imagewidth': 448,
                'imageheight': 448,
              },
            ],
          },
        ],
    'layers': [
      {
        'type': 'objectgroup',
        'name': 'casillas',
        'objects':
            casillas ??
            [
              _platform(id: 0, x: 1000, y: 3000),
              _platform(id: 1, x: 1400, y: 2800, gid: 0x80000001),
            ],
      },
      {
        'type': 'group',
        'name': 'carpeta',
        'layers': [
          {
            'type': 'objectgroup',
            'name': 'objetos',
            'objects':
                objetos ??
                [
                  {'id': 50, 'gid': 2, 'x': 1000, 'y': 2900},
                ],
          },
        ],
      },
    ],
  };
}

Map<String, dynamic> _platform({
  required int id,
  required double x,
  required double y,
  int gid = 1,
}) {
  return {
    'id': id + 10,
    'gid': gid,
    'x': x,
    'y': y,
    'width': 384,
    'height': 320,
    'properties': [
      {'name': 'casilla', 'type': 'int', 'value': id},
    ],
  };
}

void main() {
  const parser = TiledMapParser();
  const dir = 'assets/maps/mapa_01';

  test('lee el tamaño del mundo y el fondo', () {
    final map = parser.parse(_tiledMap(), mapDir: dir);

    expect(map.size, const Size(2880, 4320));
    expect(map.background, 'assets/maps/mapa_01/fondo.png');
  });

  test('las casillas usan el centro como ancla', () {
    final map = parser.parse(_tiledMap(), mapDir: dir);
    final tile = map.tiles[0]!;

    expect(tile.anchor, const Offset(1000, 3000));
    expect(tile.sprite.rect, const Rect.fromLTWH(808, 2840, 384, 320));
    expect(tile.sprite.asset, 'assets/images/mapa/piezas/plataforma_01.png');
    expect(tile.sprite.flipX, isFalse);
  });

  test('respeta el volteo horizontal de Tiled', () {
    final map = parser.parse(_tiledMap(), mapDir: dir);

    expect(map.tiles[1]!.sprite.flipX, isTrue);
    expect(map.tiles[1]!.anchor, const Offset(1400, 2800));
  });

  test('los objetos con alineación inferior se apoyan en su base', () {
    final map = parser.parse(_tiledMap(), mapDir: dir);
    final shop = map.objects.single;

    expect(shop.asset, 'assets/images/mapa/piezas/tienda.png');
    expect(shop.rect, const Rect.fromLTWH(776, 2452, 448, 448));
    expect(shop.depth, 2900);
  });

  test('missingTiles dice qué casillas faltan', () {
    final map = parser.parse(_tiledMap(), mapDir: dir);

    expect(map.missingTiles([0, 1, 2, 3]), [2, 3]);
  });

  test('falla si una plataforma no tiene la propiedad casilla', () {
    final withoutId = {'id': 99, 'gid': 1, 'x': 0, 'y': 0};

    expect(
      () => parser.parse(_tiledMap(casillas: [withoutId]), mapDir: dir),
      throwsA(isA<TiledMapException>()),
    );
  });

  test('falla si una casilla está repetida', () {
    final repeated = [
      _platform(id: 3, x: 0, y: 0),
      _platform(id: 3, x: 500, y: 0),
    ];

    expect(
      () => parser.parse(_tiledMap(casillas: repeated), mapDir: dir),
      throwsA(
        isA<TiledMapException>().having(
          (e) => e.message,
          'message',
          contains('3'),
        ),
      ),
    );
  });

  test('pide incrustar los conjuntos externos', () {
    final external = [
      {'firstgid': 1, 'source': 'piezas.tsj'},
    ];

    expect(
      () => parser.parse(_tiledMap(tilesets: external), mapDir: dir),
      throwsA(
        isA<TiledMapException>().having(
          (e) => e.message,
          'message',
          contains('Incrustar'),
        ),
      ),
    );
  });

  group('resolvePath', () {
    test('quita los .. y usa barras normales', () {
      expect(
        TiledMapParser.resolvePath(dir, r'..\..\images\mapa\a.png'),
        'assets/images/mapa/a.png',
      );
    });

    test('rechaza imágenes fuera de assets', () {
      expect(
        () => TiledMapParser.resolvePath(dir, '../../../../Escritorio/a.png'),
        throwsA(isA<TiledMapException>()),
      );
    });
  });
}
